import { spawn } from 'node:child_process';
import { readFile } from 'node:fs/promises';
import { Client } from 'pg';
import { parse } from 'dotenv';
const env = { ...process.env, ...parse(await readFile('.env')) };
const url = new URL(env.DATABASE_URL);
if (!['127.0.0.1', 'localhost'].includes(url.hostname))
  throw new Error('Servidor visual limitado ao banco local.');
const admin = new Client({ connectionString: env.DATABASE_URL });
await admin.connect();
if (
  !(await admin.query("SELECT 1 FROM pg_database WHERE datname='miar_test'"))
    .rowCount
)
  await admin.query('CREATE DATABASE miar_test');
await admin.end();
url.pathname = '/miar_test';
env.DATABASE_URL = url.toString();
env.PORT = '3301';
env.SESSION_DIR = '../.runtime/sessoes-test';
const p = spawn(process.execPath, ['dist/main.js'], {
  env,
  windowsHide: true,
  stdio: 'inherit',
});
process.on('SIGINT', () => p.kill());
process.on('SIGTERM', () => p.kill());
