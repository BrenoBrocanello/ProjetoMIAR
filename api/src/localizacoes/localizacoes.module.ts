import {
  Controller,
  ForbiddenException,
  Get,
  Injectable,
  Module,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { SessaoGuard, type UsuarioRequest } from '../auth/sessao';
import { FiltrosDto } from '../common/dtos';
import { OcorrenciasModule } from '../ocorrencias/ocorrencias.module';
import { OcorrenciasRepository } from '../ocorrencias/ocorrencias.repository';
import { MapaController, MapaService } from './mapa';

@Injectable()
export class LocalizacoesService {
  constructor(private readonly ocorrencias: OcorrenciasRepository) {}
  radar(perfil: string, f: FiltrosDto) {
    if (perfil === 'Cidadão')
      throw new ForbiddenException(
        'O radar é destinado a protetores e ONGs (CU09).',
      );
    return this.ocorrencias.list(f, undefined, true);
  }
}
@Controller('localizacoes')
@UseGuards(SessaoGuard)
export class LocalizacoesController {
  constructor(private readonly service: LocalizacoesService) {}
  @Get('radar') radar(@Req() r: UsuarioRequest, @Query() f: FiltrosDto) {
    return this.service.radar(r.usuario.tipo_usuario, f);
  }
}
@Module({
  imports: [OcorrenciasModule],
  providers: [LocalizacoesService, MapaService],
  controllers: [LocalizacoesController, MapaController],
})
export class LocalizacoesModule {}
