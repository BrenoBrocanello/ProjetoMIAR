import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import type { PoolClient } from 'pg';
import { ResultadosIA } from './resultados-ia';
import { backupLogico } from './backup';
const legacyTables = [
  'USUARIO',
  'CIDADAO',
  'PROTETOR',
  'ONG',
  'OCORRENCIA_ANIMAL',
  'LOCALIZACAC',
  'FOTO',
  'CONTATO',
  'CORRESPONDENCIA_IA',
];

export async function prepararMaster(
  db: PoolClient,
): Promise<string | undefined> {
  // Trava de sessão também protege dois servidores iniciados simultaneamente.
  await db.query('SELECT pg_advisory_lock(10112026)');
  try {
    const old = await db.query(
      `SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='CIDADAO'`,
    );
    const sql = await readFile(
      join(process.cwd(), 'database/schema.sql'),
      'utf8',
    );
    if (!old.rowCount) {
      await db.query(sql);
      return;
    }
    await db.query('BEGIN ISOLATION LEVEL REPEATABLE READ');
    try {
      const file = await backupLogico(db, legacyTables);
      await db.query('CREATE SCHEMA miar_antes_master');
      for (const table of legacyTables)
        await db.query(
          `ALTER TABLE public."${table}" SET SCHEMA miar_antes_master`,
        );
      await db.query(sql);
      await db.query(`INSERT INTO "USUARIO" (id_usuario,nome,email,senha,telefone,documento,tipo_usuario,ativo) OVERRIDING SYSTEM VALUE
        SELECT u.id_usuario,u.nome,u.email,u.senha,u.telefone,COALESCE(c.cpf,p.documento,g.cnpj),u.tipo_usuario,u.ativo
        FROM miar_antes_master."USUARIO" u
        LEFT JOIN miar_antes_master."CIDADAO" c USING(id_usuario)
        LEFT JOIN miar_antes_master."PROTETOR" p USING(id_usuario)
        LEFT JOIN miar_antes_master."ONG" g USING(id_usuario)`);
      await db.query(
        `INSERT INTO "ESPECIE"(nome) SELECT min(especie) FROM miar_antes_master."OCORRENCIA_ANIMAL" GROUP BY lower(especie)`,
      );
      await db.query(
        `INSERT INTO "CIDADE"(nome) SELECT min(cidade) FROM miar_antes_master."LOCALIZACAC" GROUP BY lower(cidade)`,
      );
      await db.query(`INSERT INTO "ANIMAL"(id_animal,id_especie,porte,descricao,url_foto,data_cadastro) OVERRIDING SYSTEM VALUE
        SELECT o.id_ocorrencia,e.id_especie,o.porte,o.descricao_fisica,
        (SELECT f.url_storage FROM miar_antes_master."FOTO" f WHERE f.id_ocorrencia=o.id_ocorrencia ORDER BY f.id_foto LIMIT 1),
        o.data_registro::date FROM miar_antes_master."OCORRENCIA_ANIMAL" o JOIN "ESPECIE" e ON lower(e.nome)=lower(o.especie)`);
      await db.query(`INSERT INTO "OCORRENCIA_ANIMAL"(id_ocorrencia,id_usuario_responsavel,id_animal,status_ocorrencia,descricao,data_registro) OVERRIDING SYSTEM VALUE
        SELECT id_ocorrencia,id_usuario_responsavel,id_ocorrencia,status_ocorrencia,
        json_build_object('miar',1,'descricao_fisica',descricao_fisica,'estado_saude',estado_saude)::text,data_registro::date
        FROM miar_antes_master."OCORRENCIA_ANIMAL"`);
      await db.query(`INSERT INTO "LOCALIZACAC"(id_localizacao,id_ocorrencia,id_cidade,latitude,longitude,endereco) OVERRIDING SYSTEM VALUE
        SELECT l.id_localizacao,l.id_ocorrencia,c.id_cidade,l.latitude,l.longitude,l.endereco
        FROM miar_antes_master."LOCALIZACAC" l JOIN "CIDADE" c ON lower(c.nome)=lower(l.cidade)`);
      await db.query(`INSERT INTO "FOTO"(id_foto,id_ocorrencia,url_storage,data_upload) OVERRIDING SYSTEM VALUE
        SELECT id_foto,id_ocorrencia,url_storage,data_upload::date FROM miar_antes_master."FOTO"`);
      await db.query(`INSERT INTO "CONTATO"(id_contato,id_ocorrencia,numero_whatsapp,whatsapp_link) OVERRIDING SYSTEM VALUE
        SELECT id_contato,id_ocorrencia,numero_whatsapp,'https://wa.me/55'||numero_whatsapp FROM miar_antes_master."CONTATO"`);
      const results = (
        await db.query('SELECT * FROM miar_antes_master."CORRESPONDENCIA_IA"')
      ).rows;
      await new ResultadosIA().importar(
        results.map((r) => ({
          ...r,
          data_analise: new Date(r.data_analise).toISOString(),
        })),
      );
      // Verificação de contagem antes de retirar as tabelas antigas; o dump completo permanece.
      for (const table of [
        'USUARIO',
        'OCORRENCIA_ANIMAL',
        'LOCALIZACAC',
        'FOTO',
        'CONTATO',
      ]) {
        const counts = (
          await db.query(`SELECT (SELECT count(*) FROM public."${table}") AS atual,
          (SELECT count(*) FROM miar_antes_master."${table}") AS anterior`)
        ).rows[0];
        if (counts.atual !== counts.anterior)
          throw new Error('Contagem divergente na migração de ' + table);
      }
      for (const [table, pk] of [
        ['USUARIO', 'id_usuario'],
        ['ANIMAL', 'id_animal'],
        ['OCORRENCIA_ANIMAL', 'id_ocorrencia'],
        ['LOCALIZACAC', 'id_localizacao'],
        ['FOTO', 'id_foto'],
        ['CONTATO', 'id_contato'],
      ]) {
        await db.query(
          `SELECT setval(pg_get_serial_sequence('"${table}"',$1),COALESCE((SELECT max("${pk}") FROM "${table}"),1),(SELECT count(*)>0 FROM "${table}"))`,
          [pk],
        );
      }
      await db.query('DROP SCHEMA miar_antes_master CASCADE');
      await db.query('COMMIT');
      return file;
    } catch (error) {
      await db.query('ROLLBACK');
      throw error;
    }
  } finally {
    await db.query('SELECT pg_advisory_unlock(10112026)');
  }
}
