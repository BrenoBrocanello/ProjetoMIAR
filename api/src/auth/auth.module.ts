import {
  Body,
  Controller,
  HttpCode,
  Injectable,
  Module,
  Post,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import * as argon2 from 'argon2';
import { LoginDto } from '../common/dtos';
import {
  UsuariosModule,
  UsuariosRepository,
} from '../usuarios/usuarios.module';
import { SessaoGuard, Sessoes, type UsuarioRequest } from './sessao';

@Injectable()
export class AuthService {
  private dummy?: string;
  constructor(
    private readonly usuarios: UsuariosRepository,
    private readonly sessoes: Sessoes,
  ) {}
  async login(dto: LoginDto) {
    const u = await this.usuarios.credentials(dto.email);
    this.dummy ??= await argon2.hash('credencial-inexistente', {
      type: argon2.argon2id,
    });
    const valid = await argon2.verify(u?.senha ?? this.dummy, dto.senha);
    if (!u || !u.ativo || !valid)
      throw new UnauthorizedException('E-mail ou senha incorretos.');
    return {
      token: await this.sessoes.criar(u.id_usuario),
      usuario: await this.usuarios.byId(u.id_usuario),
    };
  }
}
@Controller('auth')
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    private readonly sessoes: Sessoes,
  ) {}
  @Post('login')
  @HttpCode(200)
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }
  @Post('logout') @HttpCode(204) @UseGuards(SessaoGuard) async logout(
    @Req() req: UsuarioRequest,
  ) {
    await this.sessoes.revogar(req.token);
  }
}
@Module({
  imports: [UsuariosModule],
  providers: [AuthService],
  controllers: [AuthController],
})
export class AuthModule {}
