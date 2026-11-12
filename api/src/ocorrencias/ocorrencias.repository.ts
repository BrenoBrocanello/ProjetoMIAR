import { Injectable, NotFoundException } from '@nestjs/common';
import { Database } from '../infra/database';
import { FiltrosDto } from '../common/dtos';
import { lerDescricao } from '../common/descricao';
import type { PoolClient } from 'pg';

// O contrato de consulta é uma projeção do DER; não acrescenta colunas às tabelas.
const joins = ` FROM "OCORRENCIA_ANIMAL" o
 JOIN "ANIMAL" a USING(id_animal) JOIN "ESPECIE" e USING(id_especie)
 JOIN "USUARIO" u ON u.id_usuario=o.id_usuario_responsavel
 JOIN "LOCALIZACAC" l USING(id_ocorrencia) JOIN "CIDADE" city USING(id_cidade)`;
const select =
  `SELECT o.*, e.nome AS especie,a.porte,row_to_json(a) AS animal,
 json_build_object('id_usuario',u.id_usuario,'nome',u.nome,'tipo_usuario',u.tipo_usuario) AS responsavel,
 json_build_object('id_localizacao',l.id_localizacao,'id_cidade',city.id_cidade,'cidade',city.nome,'estado',city.estado,
 'latitude',l.latitude,'longitude',l.longitude,'endereco',l.endereco) AS localizacao,
 COALESCE((SELECT json_agg(f ORDER BY f.id_foto) FROM "FOTO" f WHERE f.id_ocorrencia=o.id_ocorrencia),'[]'::json) AS fotos,
 CASE WHEN o.status_ocorrencia NOT IN ('Adotado','Resgatado') THEN
 (SELECT json_build_object('numero_whatsapp',c.numero_whatsapp,'whatsapp_link',c.whatsapp_link)
 FROM "CONTATO" c WHERE c.id_ocorrencia=o.id_ocorrencia ORDER BY c.id_contato LIMIT 1) ELSE NULL END AS contato` +
  joins;

@Injectable()
export class OcorrenciasRepository {
  constructor(readonly db: Database) {}
  private projetar(row: Record<string, any>): Record<string, any> {
    // ANIMAL.url_foto é público somente como URL de foto, sem dados de contato.
    return { ...row, ...lerDescricao(row.descricao) };
  }
  async get(
    id: number,
    executor: PoolClient | Database['pool'] = this.db.pool,
    owner = false,
  ) {
    const r = await executor.query(select + ' WHERE o.id_ocorrencia=$1', [id]);
    if (!r.rowCount) throw new NotFoundException('Ocorrência não encontrada.');
    const o = this.projetar(r.rows[0]);
    if (owner)
      o.contato = (
        await executor.query(
          'SELECT numero_whatsapp,whatsapp_link FROM "CONTATO" WHERE id_ocorrencia=$1 ORDER BY id_contato LIMIT 1',
          [id],
        )
      ).rows[0];
    return o;
  }
  async list(f: FiltrosDto, owner?: number, all = false) {
    const args: unknown[] = [],
      where: string[] = [];
    const condition = (sql: string, value: unknown) => {
      args.push(value);
      where.push(sql.replace('?', '$' + args.length));
    };
    if (owner) condition('o.id_usuario_responsavel=?', owner);
    if (f.status) condition('o.status_ocorrencia=?', f.status);
    if (f.especie) condition('lower(e.nome)=lower(?)', f.especie.trim());
    if (f.porte) condition('lower(a.porte)=lower(?)', f.porte.trim());
    if (f.cidade) condition('lower(city.nome)=lower(?)', f.cidade.trim());
    const base = where.length ? ' WHERE ' + where.join(' AND ') : '';
    const total = Number(
      (await this.db.pool.query('SELECT count(*)' + joins + base, args)).rows[0]
        .count,
    );
    args.push(all ? 1000 : 24, f.pagina * (all ? 1000 : 24));
    const items = (
      await this.db.pool.query(
        select +
          base +
          ` ORDER BY o.data_registro DESC,o.id_ocorrencia DESC LIMIT $${args.length - 1} OFFSET $${args.length}`,
        args,
      )
    ).rows.map((row) => this.projetar(row));
    return { items, total, pagina: f.pagina };
  }
}
