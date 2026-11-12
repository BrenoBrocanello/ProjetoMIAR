import {
  Body,
  ConflictException,
  Controller,
  Get,
  Injectable,
  Module,
  NotFoundException,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import * as argon2 from 'argon2';
import { Database } from '../infra/database';
import { CadastroDto, PerfilDto, telefoneBR } from '../common/dtos';
import { SessaoGuard, type UsuarioRequest } from '../auth/sessao';

@Injectable()
export class UsuariosRepository {
  constructor(private readonly db: Database) {}
  async byId(id: number) {
    const r = await this.db.pool.query(
      `SELECT id_usuario,nome,email,telefone,documento,tipo_usuario,ativo FROM "USUARIO" WHERE id_usuario=$1`,
      [id],
    );
    if (!r.rowCount) throw new NotFoundException('Usuário não encontrado.');
    return r.rows[0];
  }
  async credentials(email: string) {
    return (
      await this.db.pool.query('SELECT * FROM "USUARIO" WHERE email=$1', [
        email.toLowerCase(),
      ])
    ).rows[0];
  }
}
@Injectable()
export class UsuariosService {
  constructor(
    private readonly db: Database,
    readonly repo: UsuariosRepository,
  ) {}
  async cadastrar(dto: CadastroDto) {
    const telefone = telefoneBR(dto.telefone);
    const senha = await argon2.hash(dto.senha, { type: argon2.argon2id });
    try {
      const id = await this.db.transaction(async (db) => {
        const r = await db.query(
          'INSERT INTO "USUARIO" (nome,email,senha,telefone,tipo_usuario,documento) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id_usuario',
          [
            dto.nome,
            dto.email.toLowerCase(),
            senha,
            telefone,
            dto.tipo_usuario,
            dto.documento ?? null,
          ],
        );
        const id = r.rows[0].id_usuario;
        return id;
      });
      return this.repo.byId(id);
    } catch (error) {
      if (error.code === '23505')
        throw new ConflictException('Este e-mail já está cadastrado.');
      throw error;
    }
  }
  async atualizar(id: number, dto: PerfilDto) {
    const telefone =
      dto.telefone === undefined ? undefined : telefoneBR(dto.telefone);
    const senha =
      dto.senha === undefined
        ? undefined
        : await argon2.hash(dto.senha, { type: argon2.argon2id });
    try {
      await this.db.transaction(async (db) => {
        const u = (
          await db.query(
            'SELECT tipo_usuario FROM "USUARIO" WHERE id_usuario=$1 FOR UPDATE',
            [id],
          )
        ).rows[0];
        if (!u) throw new NotFoundException('Usuário não encontrado.');
        const values = {
          nome: dto.nome,
          email: dto.email?.toLowerCase(),
          telefone,
          senha,
          documento: dto.documento,
        };
        for (const [field, value] of Object.entries(values))
          if (value !== undefined)
            await db.query(
              `UPDATE "USUARIO" SET ${field}=$1 WHERE id_usuario=$2`,
              [value, id],
            );
      });
      return this.repo.byId(id);
    } catch (error) {
      if (error.code === '23505')
        throw new ConflictException('Este e-mail já está cadastrado.');
      throw error;
    }
  }
}
@Controller('usuarios')
export class UsuariosController {
  constructor(private readonly service: UsuariosService) {}
  @Post('cadastro') cadastrar(@Body() dto: CadastroDto) {
    return this.service.cadastrar(dto);
  }
  @Get('me') @UseGuards(SessaoGuard) me(@Req() req: UsuarioRequest) {
    return this.service.repo.byId(req.usuario.id_usuario);
  }
  @Patch('me') @UseGuards(SessaoGuard) atualizar(
    @Req() req: UsuarioRequest,
    @Body() dto: PerfilDto,
  ) {
    return this.service.atualizar(req.usuario.id_usuario, dto);
  }
}
@Module({
  controllers: [UsuariosController],
  providers: [UsuariosRepository, UsuariosService],
  exports: [UsuariosRepository, UsuariosService],
})
export class UsuariosModule {}
