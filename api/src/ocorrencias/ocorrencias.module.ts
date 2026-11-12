import {
  BadRequestException,
  Body,
  Controller,
  ConflictException,
  Delete,
  ForbiddenException,
  Get,
  Injectable,
  Logger,
  Module,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Put,
  Query,
  Req,
  Sse,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { SessaoGuard, Sessoes, type UsuarioRequest } from '../auth/sessao';
import { takeUntil } from 'rxjs';
import {
  FiltrosDto,
  OcorrenciaDto,
  parseOcorrencia,
  StatusDto,
  telefoneBR,
} from '../common/dtos';
import { codificarDescricao } from '../common/descricao';
import { FotosModule, FotosService } from '../fotos/fotos.module';
import {
  CorrespondenciasModule,
  CorrespondenciasService,
} from '../correspondencias/correspondencias.module';
import { OcorrenciasRepository } from './ocorrencias.repository';
import { Eventos } from '../infra/eventos';

@Injectable()
export class OcorrenciasService {
  private readonly logger = new Logger(OcorrenciasService.name);
  constructor(
    readonly repo: OcorrenciasRepository,
    private readonly fotos: FotosService,
    private readonly matches: CorrespondenciasService,
    readonly eventos: Eventos,
  ) {}
  async propria(id: number, user: number) {
    const o = await this.repo.get(id);
    if (o.id_usuario_responsavel !== user)
      throw new ForbiddenException(
        'Somente o responsável pode gerenciar esta ocorrência.',
      );
    return this.repo.get(id, this.repo.db.pool, true);
  }
  private async limpar(urls: string[]) {
    for (const url of urls)
      await this.fotos
        .excluir(url)
        .catch(() =>
          this.logger.warn('Limpeza de objeto pendente no armazenamento.'),
        );
  }
  async salvar(
    user: number,
    d: OcorrenciaDto,
    files: Express.Multer.File[],
    id?: number,
  ) {
    const old = id ? await this.propria(id, user) : undefined;
    const kept = old
      ? old.fotos.filter(
          (f) =>
            d.fotos_mantidas === undefined ||
            d.fotos_mantidas.includes(f.id_foto),
        )
      : [];
    if (
      d.fotos_mantidas &&
      (!old ||
        d.fotos_mantidas.some((x) => !old.fotos.some((f) => f.id_foto === x)))
    )
      throw new BadRequestException(
        'Fotografia não pertence a esta ocorrência.',
      );
    if (kept.length + (files?.length ?? 0) < 1)
      throw new BadRequestException('Adicione pelo menos uma fotografia.');
    if (kept.length + (files?.length ?? 0) > 6)
      throw new BadRequestException('Mantenha até seis fotografias.');
    const novas = files?.length ? await this.fotos.preparar(files) : [];
    const analise = [...novas];
    for (const f of kept)
      analise.push({
        key: this.fotos.key(f.url_storage),
        buffer: Buffer.alloc(0),
        vetor: await this.fotos.vetor(f.url_storage),
      });
    const scores = await this.matches.analisar(d.especie, analise, id);
    const saved: string[] = [];
    let desfazer: (() => Promise<void>) | undefined;
    let committed = false;
    try {
      for (const f of novas) saved.push(await this.fotos.salvar(f));
      const result = await this.repo.db.transaction(async (db) => {
        let occurrence = id;
        let animal: number;
        const especie = (
          await db.query(
            `INSERT INTO "ESPECIE"(nome) VALUES($1)
     ON CONFLICT(lower(nome)) DO UPDATE SET nome="ESPECIE".nome RETURNING id_especie`,
            [d.especie],
          )
        ).rows[0].id_especie;
        const city = (
          await db.query(
            `INSERT INTO "CIDADE"(nome,estado) VALUES($1,$2)
     ON CONFLICT(lower(nome),lower(COALESCE(estado,''))) DO UPDATE SET nome="CIDADE".nome RETURNING id_cidade`,
            [d.localizacao.cidade, d.localizacao.estado?.toUpperCase() || null],
          )
        ).rows[0].id_cidade;
        if (id) {
          const lock = (
            await db.query(
              'SELECT id_usuario_responsavel,id_animal FROM "OCORRENCIA_ANIMAL" WHERE id_ocorrencia=$1 FOR UPDATE',
              [id],
            )
          ).rows[0];
          if (!lock || lock.id_usuario_responsavel !== user)
            throw new ForbiddenException(
              'Ocorrência indisponível para alteração.',
            );
          const atuais = (await db.query('SELECT id_foto FROM "FOTO" WHERE id_ocorrencia=$1', [id])).rows;
          if (atuais.length !== old!.fotos.length || atuais.some(f => !old!.fotos.some(anterior => anterior.id_foto === f.id_foto))) {
            throw new ConflictException('As fotografias foram alteradas em outra sessão. Reabra a ocorrência antes de salvar.');
          }
          animal = lock.id_animal;
          // Uma alteração própria não modifica características usadas por outra ocorrência.
          const shared = (
            await db.query(
              'SELECT 1 FROM "OCORRENCIA_ANIMAL" WHERE id_animal=$1 AND id_ocorrencia<>$2 LIMIT 1',
              [animal, id],
            )
          ).rowCount;
          if (shared)
            animal = (
              await db.query(
                `INSERT INTO "ANIMAL"(id_especie,nome,porte,descricao,idade,genero,cor,url_foto,data_cadastro)
      SELECT id_especie,nome,porte,descricao,idade,genero,cor,url_foto,data_cadastro FROM "ANIMAL" WHERE id_animal=$1 RETURNING id_animal`,
                [animal],
              )
            ).rows[0].id_animal;
          await db.query(
            'UPDATE "OCORRENCIA_ANIMAL" SET id_animal=$1,status_ocorrencia=$2,descricao=$3 WHERE id_ocorrencia=$4',
            [
              animal,
              d.status_ocorrencia,
              codificarDescricao(d.descricao_fisica, d.estado_saude),
              id,
            ],
          );
          await db.query(
            'DELETE FROM "FOTO" WHERE id_ocorrencia=$1 AND NOT(id_foto=ANY($2::int[]))',
            [id, kept.map((f) => f.id_foto)],
          );
        } else {
          animal = (
            await db.query(
              'INSERT INTO "ANIMAL"(id_especie,porte,descricao) VALUES($1,$2,$3) RETURNING id_animal',
              [especie, d.porte, d.descricao_fisica],
            )
          ).rows[0].id_animal;
          occurrence = (
            await db.query(
              'INSERT INTO "OCORRENCIA_ANIMAL"(id_animal,status_ocorrencia,descricao,id_usuario_responsavel) VALUES($1,$2,$3,$4) RETURNING id_ocorrencia',
              [
                animal,
                d.status_ocorrencia,
                codificarDescricao(d.descricao_fisica, d.estado_saude),
                user,
              ],
            )
          ).rows[0].id_ocorrencia;
        }
        await db.query('SELECT pg_advisory_xact_lock(44100,$1)', [occurrence]);
        await db.query(
          'UPDATE "ANIMAL" SET id_especie=$1,porte=$2,descricao=$3,url_foto=$4 WHERE id_animal=$5',
          [
            especie,
            d.porte,
            d.descricao_fisica,
            kept[0]?.url_storage ?? saved[0],
            animal!,
          ],
        );
        await db.query(
          `INSERT INTO "LOCALIZACAC"(id_ocorrencia,id_cidade,latitude,longitude,endereco) VALUES($1,$2,$3,$4,$5)
     ON CONFLICT(id_ocorrencia) DO UPDATE SET id_cidade=excluded.id_cidade,latitude=excluded.latitude,longitude=excluded.longitude,endereco=excluded.endereco`,
          [
            occurrence,
            city,
            d.localizacao.latitude,
            d.localizacao.longitude,
            d.localizacao.endereco ?? null,
          ],
        );
        const contact = (
          await db.query(
            'SELECT id_contato FROM "CONTATO" WHERE id_ocorrencia=$1 ORDER BY id_contato LIMIT 1',
            [occurrence],
          )
        ).rows[0];
        const number = telefoneBR(d.numero_whatsapp),
          url = 'https://wa.me/55' + number;
        if (contact)
          await db.query(
            'UPDATE "CONTATO" SET numero_whatsapp=$1,whatsapp_link=$2 WHERE id_contato=$3',
            [number, url, contact.id_contato],
          );
        else
          await db.query(
            'INSERT INTO "CONTATO"(id_ocorrencia,numero_whatsapp,whatsapp_link,data_contato) VALUES($1,$2,$3,CURRENT_DATE)',
            [occurrence, number, url],
          );
        for (const url of saved)
          await db.query(
            'INSERT INTO "FOTO"(id_ocorrencia,url_storage) VALUES($1,$2)',
            [occurrence, url],
          );
        desfazer = await this.matches.registrar(db, occurrence!, scores);
        return this.repo.get(occurrence!, db);
      });
      committed = true;
      if (old)
        await this.limpar(
          old.fotos
            .filter((f) => !kept.some((k) => k.id_foto === f.id_foto))
            .map((f) => f.url_storage),
        );
      this.eventos.publicar(result.id_ocorrencia);
      return result;
    } catch (error) {
      if (!committed) {
        if (desfazer) await desfazer();
        await this.limpar(saved);
      }
      throw error;
    }
  }
  async status(id: number, user: number, status: string) {
    await this.propria(id, user);
    await this.repo.db.pool.query(
      'UPDATE "OCORRENCIA_ANIMAL" SET status_ocorrencia=$1 WHERE id_ocorrencia=$2 AND id_usuario_responsavel=$3',
      [status, id, user],
    );
    this.eventos.publicar(id);
    return this.repo.get(id);
  }
  async excluir(id: number, user: number) {
    const o = await this.propria(id, user);
    await this.repo.db.transaction(async (db) => {
      await db.query('SELECT pg_advisory_xact_lock(44100,$1)', [id]);
      await db.query(
        'DELETE FROM "OCORRENCIA_ANIMAL" WHERE id_ocorrencia=$1 AND id_usuario_responsavel=$2',
        [id, user],
      );
      await db.query(
        'DELETE FROM "ANIMAL" WHERE id_animal=$1 AND NOT EXISTS(SELECT 1 FROM "OCORRENCIA_ANIMAL" WHERE id_animal=$1)',
        [o.animal.id_animal],
      );
    });
    await this.limpar(o.fotos.map((f) => f.url_storage));
    this.eventos.publicar(id);
    return { excluida: true };
  }
}
const upload = () =>
  FilesInterceptor('fotos', 6, {
    storage: memoryStorage(),
    limits: {
      fileSize: 10 * 1024 * 1024,
      files: 6,
      fields: 1,
      fieldSize: 32000,
    },
  });
@Controller('ocorrencias')
@UseGuards(SessaoGuard)
export class OcorrenciasController {
  constructor(
    private readonly service: OcorrenciasService,
    private readonly sessoes: Sessoes,
  ) {}
  @Sse('eventos') eventos(@Req() req: UsuarioRequest) {
    return this.service.eventos
      .assinar()
      .pipe(takeUntil(this.sessoes.encerramento(req.token)));
  }
  @Get() list(@Query() f: FiltrosDto) {
    return this.service.repo.list(f);
  }
  @Get('minhas') mine(@Req() r: UsuarioRequest, @Query() f: FiltrosDto) {
    return this.service.repo.list(f, r.usuario.id_usuario);
  }
  @Get(':id/editar') edit(
    @Req() r: UsuarioRequest,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.service.propria(id, r.usuario.id_usuario);
  }
  @Get(':id') get(@Param('id', ParseIntPipe) id: number) {
    return this.service.repo.get(id);
  }
  @Post() @UseInterceptors(upload()) async create(
    @Req() r: UsuarioRequest,
    @Body('dados') raw: string,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    return this.service.salvar(
      r.usuario.id_usuario,
      await parseOcorrencia(raw),
      files,
    );
  }
  @Put(':id') @UseInterceptors(upload()) async update(
    @Req() r: UsuarioRequest,
    @Param('id', ParseIntPipe) id: number,
    @Body('dados') raw: string,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    return this.service.salvar(
      r.usuario.id_usuario,
      await parseOcorrencia(raw),
      files,
      id,
    );
  }
  @Patch(':id/status') status(
    @Req() r: UsuarioRequest,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: StatusDto,
  ) {
    return this.service.status(id, r.usuario.id_usuario, dto.status_ocorrencia);
  }
  @Delete(':id') delete(
    @Req() r: UsuarioRequest,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.service.excluir(id, r.usuario.id_usuario);
  }
}
@Module({
  imports: [FotosModule, CorrespondenciasModule],
  providers: [OcorrenciasRepository, OcorrenciasService],
  controllers: [OcorrenciasController],
  exports: [OcorrenciasRepository],
})
export class OcorrenciasModule {}
