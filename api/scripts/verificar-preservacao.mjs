import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { Client } from 'pg';
import { parse } from 'dotenv';
import assert from 'node:assert/strict';

const dir = '../evidencias/auditoria-2026-11-11';
const before = JSON.parse(await readFile(dir + '/banco-principal-preservado.json', 'utf8'));
const env = parse(await readFile('.env'));
const url = new URL(env.DATABASE_URL);
assert(['127.0.0.1', 'localhost'].includes(url.hostname));
assert.equal(url.pathname, '/miar');
const db = new Client({ connectionString: env.DATABASE_URL });
const after = {};
await db.connect();
try {
  await db.query('BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY');
  for (const table of Object.keys(before)) {
    assert(/^[A-Z_]+$/.test(table));
    const { rows } = await db.query(`SELECT to_jsonb(t) AS registro FROM "${table}" t ORDER BY to_jsonb(t)::text`);
    after[table] = { registros: rows.length,
      sha256: createHash('sha256').update(JSON.stringify(rows.map(r => r.registro))).digest('hex') };
  }
  await db.query('COMMIT');
  assert.deepEqual(after, before, 'Dados principais diferem do inicio da auditoria.');
  await writeFile(dir + '/banco-principal-pos-auditoria.json', JSON.stringify({ preservado: true, tabelas: after }, null, 2));
  console.log('Nove tabelas do banco principal preservadas: contagens e hashes identicos. Nenhum dado pessoal exportado.');
} finally { await db.end(); }
