import {
  CanActivate,
  ExecutionContext,
  Global,
  Injectable,
  Module,
  OnModuleInit,
  UnauthorizedException,
} from '@nestjs/common';
import { randomBytes, createHash } from 'node:crypto';
import { mkdir, readdir, readFile, unlink, writeFile } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { Request } from 'express';
import { Database } from '../infra/database';
import { Subject, filter } from 'rxjs';

export interface UsuarioRequest extends Request {
  usuario: { id_usuario: number; tipo_usuario: string };
  token: string;
}
@Injectable()
export class Sessoes implements OnModuleInit {
  private readonly revogacoes = new Subject<string>();
  encerramento(token: string) {
    const key = this.key(token);
    return this.revogacoes.pipe(filter((value) => value === key));
  }
  private readonly dir = resolve(
    process.env.SESSION_DIR ?? '../.runtime/sessions',
  );
  private key(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }
  async onModuleInit() {
    await mkdir(this.dir, { recursive: true, mode: 0o700 });
    for (const file of await readdir(this.dir)) {
      if (!/^[a-f0-9]{64}$/.test(file)) continue;
      try {
        const s = JSON.parse(await readFile(join(this.dir, file), 'utf8'));
        if (s.expira < Date.now()) await unlink(join(this.dir, file));
      } catch {
        /* arquivo inválido nunca autentica */
      }
    }
  }
  async criar(id_usuario: number) {
    const token = randomBytes(32).toString('hex');
    await writeFile(
      join(this.dir, this.key(token)),
      JSON.stringify({ id_usuario, expira: Date.now() + 7 * 86400000 }),
      { mode: 0o600, flag: 'wx' },
    );
    return token;
  }
  async consultar(token: string): Promise<number> {
    if (!/^[a-f0-9]{64}$/.test(token))
      throw new UnauthorizedException('Sua sessão expirou. Entre novamente.');
    try {
      const s = JSON.parse(
        await readFile(join(this.dir, this.key(token)), 'utf8'),
      );
      if (s.expira > Date.now()) return s.id_usuario;
    } catch {
      /* sessão inexistente */
    }
    throw new UnauthorizedException('Sua sessão expirou. Entre novamente.');
  }
  async revogar(token: string) {
    await unlink(join(this.dir, this.key(token))).catch(() => {});
    this.revogacoes.next(this.key(token));
  }
}
@Injectable()
export class SessaoGuard implements CanActivate {
  constructor(
    private readonly sessoes: Sessoes,
    private readonly db: Database,
  ) {}
  async canActivate(context: ExecutionContext) {
    const req = context.switchToHttp().getRequest<UsuarioRequest>();
    const token = req.headers.authorization?.match(
      /^Bearer ([a-f0-9]{64})$/,
    )?.[1];
    if (!token)
      throw new UnauthorizedException('Entre na sua conta para continuar.');
    const id = await this.sessoes.consultar(token);
    const u = (
      await this.db.pool.query(
        'SELECT id_usuario,tipo_usuario FROM "USUARIO" WHERE id_usuario=$1 AND ativo=true',
        [id],
      )
    ).rows[0];
    if (!u) throw new UnauthorizedException('Conta indisponível.');
    req.usuario = u;
    req.token = token;
    return true;
  }
}
@Global()
@Module({ providers: [Sessoes, SessaoGuard], exports: [Sessoes, SessaoGuard] })
export class SessaoModule {}
