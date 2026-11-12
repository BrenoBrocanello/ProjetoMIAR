import {
  Controller,
  Get,
  GoneException,
  Injectable,
  Module,
  Param,
  ParseIntPipe,
  UseGuards,
} from '@nestjs/common';
import { SessaoGuard } from '../auth/sessao';
import { telefoneBR } from '../common/dtos';
import { OcorrenciasModule } from '../ocorrencias/ocorrencias.module';
import { OcorrenciasRepository } from '../ocorrencias/ocorrencias.repository';

@Injectable()
export class ContatosService {
  constructor(private readonly ocorrencias: OcorrenciasRepository) {}
  async link(id: number) {
    const o = await this.ocorrencias.get(id);
    if (!o.contato)
      throw new GoneException(
        'Esta ocorrência foi encerrada. O contato público está desabilitado.',
      );
    return { url: `https://wa.me/55${telefoneBR(o.contato.numero_whatsapp)}` };
  }
}
@Controller('contatos')
@UseGuards(SessaoGuard)
export class ContatosController {
  constructor(private readonly service: ContatosService) {}
  @Get(':id') get(@Param('id', ParseIntPipe) id: number) {
    return this.service.link(id);
  }
}
@Module({
  imports: [OcorrenciasModule],
  providers: [ContatosService],
  controllers: [ContatosController],
})
export class ContatosModule {}
