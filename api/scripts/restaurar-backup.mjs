import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { Client } from 'pg';
import { parse } from 'dotenv';

// Restaura somente em banco local vazio. Nunca apaga tabelas existentes.
const file = process.argv[2];
if (!file) throw new Error('Informe o arquivo de backup JSON.');
const raw = await readFile(file, 'utf8');
const hash = (await readFile(file + '.sha256', 'utf8')).trim();
if (createHash('sha256').update(raw).digest('hex') !== hash)
  throw new Error('Checksum do backup inválido.');
const data = JSON.parse(raw);
if (data.format !== 'miar-logical-v1')
  throw new Error('Formato de backup inválido.');
const env = { ...parse(await readFile('.env')), ...process.env };
const url = new URL(env.DATABASE_URL);
if (!['127.0.0.1', 'localhost'].includes(url.hostname))
  throw new Error('Restauração limitada ao banco local.');
const db = new Client({ connectionString: env.DATABASE_URL });
const quote = (x) => '"' + x.replaceAll('"', '""') + '"';
await db.connect();
try {
  await db.query('BEGIN');
  if (
    (
      await db.query(
        "SELECT 1 FROM pg_tables WHERE schemaname='public' LIMIT 1",
      )
    ).rowCount
  )
    throw new Error(
      'O banco de destino precisa estar vazio. Nenhuma tabela foi apagada.',
    );
  for (const [name, t] of Object.entries(data.tables)) {
    const columns = t.columns.map(
      (c) =>
        quote(c.name) +
        ' ' +
        c.type +
        (c.identity
          ? ' GENERATED ' +
            (c.identity === 'a' ? 'ALWAYS' : 'BY DEFAULT') +
            ' AS IDENTITY'
          : c.default
            ? ' DEFAULT ' + c.default
            : '') +
        (c.required ? ' NOT NULL' : ''),
    );
    await db.query(
      'CREATE TABLE ' + quote(name) + '(' + columns.join(',') + ')',
    );
    for (const row of t.rows) {
      const fields = Object.keys(row);
      await db.query(
        'INSERT INTO ' +
          quote(name) +
          '(' +
          fields.map(quote).join(',') +
          ') OVERRIDING SYSTEM VALUE VALUES(' +
          fields.map((_, i) => '$' + (i + 1)).join(',') +
          ')',
        Object.values(row),
      );
    }
    for (const c of t.columns.filter((c) => c.identity))
      await db.query(
        'SELECT setval(pg_get_serial_sequence($1,$2),COALESCE((SELECT max(' +
          quote(c.name) +
          ') FROM ' +
          quote(name) +
          '),1),(SELECT count(*)>0 FROM ' +
          quote(name) +
          '))',
        [quote(name), c.name],
      );
  }
  for (const foreign of [false, true])
    for (const [name, t] of Object.entries(data.tables))
      for (const c of t.constraints.filter((c) => (c.type === 'f') === foreign))
        await db.query(
          'ALTER TABLE ' +
            quote(name) +
            ' ADD CONSTRAINT ' +
            quote(c.name) +
            ' ' +
            c.definition,
        );
  for (const t of Object.values(data.tables))
    for (const i of t.indexes) await db.query(i.definition);
  await db.query('COMMIT');
  console.log(
    'Backup restaurado no banco local vazio, incluindo dados, chaves e índices.',
  );
} catch (error) {
  await db.query('ROLLBACK');
  throw error;
} finally {
  await db.end();
}
