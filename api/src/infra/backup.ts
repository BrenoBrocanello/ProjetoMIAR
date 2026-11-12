import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import type { PoolClient } from 'pg';

// Snapshot lógico consistente, independente de pg_dump no PostgreSQL portátil.
// Deve ser chamado dentro da transação REPEATABLE READ e antes da migração.
export async function backupLogico(db: PoolClient, tables: string[]) {
  const snapshot: Record<string, unknown> = {};
  for (const table of tables) {
    const columns = (
      await db.query(
        `SELECT a.attname AS name,format_type(a.atttypid,a.atttypmod) AS type,
      a.attnotnull AS required,a.attidentity AS identity,pg_get_expr(d.adbin,d.adrelid) AS default
      FROM pg_attribute a JOIN pg_class t ON t.oid=a.attrelid JOIN pg_namespace n ON n.oid=t.relnamespace
      LEFT JOIN pg_attrdef d ON d.adrelid=t.oid AND d.adnum=a.attnum
      WHERE n.nspname='public' AND t.relname=$1 AND a.attnum>0 AND NOT a.attisdropped ORDER BY a.attnum`,
        [table],
      )
    ).rows;
    const constraints = (
      await db.query(
        `SELECT c.conname AS name,c.contype AS type,pg_get_constraintdef(c.oid) AS definition
      FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace
      WHERE n.nspname='public' AND t.relname=$1`,
        [table],
      )
    ).rows;
    const indexes = (
      await db.query(
        `SELECT pg_get_indexdef(i.indexrelid) AS definition
      FROM pg_index i JOIN pg_class t ON t.oid=i.indrelid JOIN pg_namespace n ON n.oid=t.relnamespace
      LEFT JOIN pg_constraint c ON c.conindid=i.indexrelid
      WHERE n.nspname='public' AND t.relname=$1 AND c.oid IS NULL`,
        [table],
      )
    ).rows;
    const rows = (
      await db.query(`SELECT row_to_json(t)::text AS row FROM "${table}" t`)
    ).rows.map((x) => JSON.parse(x.row));
    snapshot[table] = { columns, constraints, indexes, rows };
  }
  const dir = resolve(process.env.BACKUP_DIR ?? '../.runtime/backups');
  await mkdir(dir, { recursive: true, mode: 0o700 });
  const name = new URL(process.env.DATABASE_URL!).pathname
    .slice(1)
    .replace(/[^a-zA-Z0-9_-]/g, '_');
  const file = join(dir, name + '-antes-master-' + Date.now() + '.json');
  const data = JSON.stringify({ format: 'miar-logical-v1', tables: snapshot });
  await writeFile(file, data, { mode: 0o600, flag: 'wx' });
  if ((await readFile(file, 'utf8')) !== data)
    throw new Error('Falha ao verificar o backup.');
  await writeFile(
    file + '.sha256',
    createHash('sha256').update(data).digest('hex'),
    { mode: 0o600, flag: 'wx' },
  );
  return file;
}
