import {
  Controller,
  Get,
  Injectable,
  Module,
  NotFoundException,
  Param,
  ParseIntPipe,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Database } from '../infra/database';
import { SessaoGuard, type UsuarioRequest } from '../auth/sessao';
import {
  FotosModule,
  FotosService,
  FotoPreparada,
} from '../fotos/fotos.module';
import { OcorrenciasRepository } from '../ocorrencias/ocorrencias.repository';
import { ResultadosIA, type ResultadoIA } from '../infra/resultados-ia';
import type { PoolClient } from 'pg';

export const assinaturaSQL = `md5(a.id_especie::text || ':' || COALESCE(
 (SELECT string_agg(f.id_foto::text || ':' || f.url_storage,',' ORDER BY f.id_foto) FROM "FOTO" f WHERE f.id_ocorrencia=o.id_ocorrencia),''))`;
type Score = { confianca: number; assinatura: string };
@Injectable()
export class CorrespondenciasRepository {
  readonly store = new ResultadosIA();
  constructor(private readonly db: Database) {}
  async lista(user: number, apenasPerdidos = true) {
    const all = await this.store.todos();
    if (!all.length) return [];
    const ids = [
      ...new Set(
        all.flatMap((x) => [
          x.id_ocorrencia_origem,
          x.id_ocorrencia_compativel,
        ]),
      ),
    ];
    const current = (
      await this.db.pool.query(
        `SELECT o.id_ocorrencia,o.id_usuario_responsavel,o.status_ocorrencia,
      ${assinaturaSQL} AS assinatura FROM "OCORRENCIA_ANIMAL" o JOIN "ANIMAL" a USING(id_animal)
      WHERE o.id_ocorrencia=ANY($1::int[])`,
        [ids],
      )
    ).rows;
    const byId = new Map(current.map((x) => [x.id_ocorrencia, x]));
    return all
      .filter((x) => {
        const lost = byId.get(x.id_ocorrencia_compativel),
          source = byId.get(x.id_ocorrencia_origem);
        return (
          lost &&
          source &&
          lost.id_usuario_responsavel === user &&
          (!apenasPerdidos || lost.status_ocorrencia === 'Perdido') &&
          (!x.assinatura_origem || x.assinatura_origem === source.assinatura) &&
          (!x.assinatura_compativel ||
            x.assinatura_compativel === lost.assinatura)
        );
      })
      .sort((a, b) => b.data_analise.localeCompare(a.data_analise))
      .slice(0, 100);
  }
  async owned(id: number, user: number) {
    const r = (await this.lista(user, false)).find(
      (x) => x.id_correspondencia === id,
    );
    if (!r) throw new NotFoundException('Correspondência não encontrada.');
    return r;
  }
}
@Injectable()
export class CorrespondenciasService {
  constructor(
    private readonly db: Database,
    private readonly fotos: FotosService,
    readonly repo: CorrespondenciasRepository,
    private readonly ocorrencias: OcorrenciasRepository,
  ) {}
  async analisar(especie: string, novas: FotoPreparada[], exclude?: number) {
    const candidates = (
      await this.db.pool.query(
        `SELECT o.id_ocorrencia,f.url_storage,${assinaturaSQL} AS assinatura
      FROM "OCORRENCIA_ANIMAL" o JOIN "ANIMAL" a USING(id_animal) JOIN "ESPECIE" e USING(id_especie) JOIN "FOTO" f USING(id_ocorrencia)
      WHERE o.status_ocorrencia='Perdido' AND lower(e.nome)=lower($1)
      AND ($2::integer IS NULL OR o.id_ocorrencia<>$2)`,
        [especie, exclude ?? null],
      )
    ).rows;
    const scores = new Map<number, Score>();
    const threshold = Number(process.env.MATCH_THRESHOLD ?? 0.9);
    if (!Number.isFinite(threshold) || threshold < 0 || threshold > 1)
      throw new Error('MATCH_THRESHOLD inválido.');
    for (const candidate of candidates) {
      const vetor = await this.fotos.vetor(candidate.url_storage);
      for (const nova of novas) {
        let score: number;
        if (this.db.hasVector)
          score = Number(
            (
              await this.db.pool.query(
                'SELECT 1 - ($1::vector <=> $2::vector) AS score',
                [JSON.stringify(nova.vetor), JSON.stringify(vetor)],
              )
            ).rows[0].score,
          );
        else {
          const dot = nova.vetor.reduce((n, v, i) => n + v * vetor[i], 0);
          const norm = Math.hypot(...nova.vetor) * Math.hypot(...vetor);
          score = norm ? dot / norm : 0;
        }
        if (score >= threshold)
          scores.set(candidate.id_ocorrencia, {
            confianca: Math.max(
              scores.get(candidate.id_ocorrencia)?.confianca ?? 0,
              Math.min(100, score * 100),
            ),
            assinatura: candidate.assinatura,
          });
      }
    }
    return scores;
  }
  async registrar(db: PoolClient, origem: number, scores: Map<number, Score>) {
    const source = (
      await db.query(
        `SELECT ${assinaturaSQL} AS assinatura FROM "OCORRENCIA_ANIMAL" o JOIN "ANIMAL" a USING(id_animal) WHERE id_ocorrencia=$1`,
        [origem],
      )
    ).rows[0];
    const rows: Omit<ResultadoIA, 'id_correspondencia'>[] = [];
    for (const [id, score] of scores) {
      const target = (
        await db.query(
          `SELECT ${assinaturaSQL} AS assinatura FROM "OCORRENCIA_ANIMAL" o JOIN "ANIMAL" a USING(id_animal)
        WHERE id_ocorrencia=$1 AND status_ocorrencia='Perdido'`,
          [id],
        )
      ).rows[0];
      if (!target || target.assinatura !== score.assinatura) continue;
      rows.push({
        id_ocorrencia_origem: origem,
        id_ocorrencia_compativel: id,
        percentual_confianca: score.confianca,
        data_analise: new Date().toISOString(),
        status_notificacao: 'Pendente',
        assinatura_origem: source.assinatura,
        assinatura_compativel: target.assinatura,
      });
    }
    return this.repo.store.substituir(origem, rows);
  }
  async detalhe(id: number, user: number) {
    const c = await this.repo.owned(id, user);
    return {
      ...c,
      origem: await this.ocorrencias.get(c.id_ocorrencia_origem),
      perdido: await this.ocorrencias.get(c.id_ocorrencia_compativel),
    };
  }
  async emitida(id: number, user: number) {
    const c = await this.repo.owned(id, user);
    await this.db.transaction(async (db) => {
      await db.query('SELECT pg_advisory_xact_lock(44100,$1)', [
        c.id_ocorrencia_origem,
      ]);
      const rows = (await this.repo.store.todos()).filter(
        (x) => x.id_ocorrencia_origem === c.id_ocorrencia_origem,
      );
      const current = rows.find((x) => x.id_correspondencia === id);
      if (!current)
        throw new NotFoundException('Correspondência não encontrada.');
      current.status_notificacao = 'Emitida';
      await this.repo.store.gravar(c.id_ocorrencia_origem, rows);
    });
    return { status_notificacao: 'Emitida' };
  }
}
@Controller('correspondencias')
@UseGuards(SessaoGuard)
export class CorrespondenciasController {
  constructor(private readonly service: CorrespondenciasService) {}
  @Get() list(@Req() r: UsuarioRequest) {
    return this.service.repo.lista(r.usuario.id_usuario);
  }
  @Get(':id') get(
    @Req() r: UsuarioRequest,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.service.detalhe(id, r.usuario.id_usuario);
  }
  @Post(':id/notificacao-emitida') emitida(
    @Req() r: UsuarioRequest,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.service.emitida(id, r.usuario.id_usuario);
  }
}
@Module({
  imports: [FotosModule],
  providers: [
    CorrespondenciasRepository,
    CorrespondenciasService,
    OcorrenciasRepository,
  ],
  controllers: [CorrespondenciasController],
  exports: [CorrespondenciasService],
})
export class CorrespondenciasModule {}
