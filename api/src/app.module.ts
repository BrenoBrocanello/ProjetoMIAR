import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { DatabaseModule } from './infra/database';
import { EventosModule } from './infra/eventos';
import { SessaoModule } from './auth/sessao';
import { AuthModule } from './auth/auth.module';
import { UsuariosModule } from './usuarios/usuarios.module';
import { OcorrenciasModule } from './ocorrencias/ocorrencias.module';
import { LocalizacoesModule } from './localizacoes/localizacoes.module';
import { FotosModule } from './fotos/fotos.module';
import { ContatosModule } from './contatos/contatos.module';
import { CorrespondenciasModule } from './correspondencias/correspondencias.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DatabaseModule,
    EventosModule,
    SessaoModule,
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 300 }]),
    AuthModule,
    UsuariosModule,
    OcorrenciasModule,
    LocalizacoesModule,
    FotosModule,
    ContatosModule,
    CorrespondenciasModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
