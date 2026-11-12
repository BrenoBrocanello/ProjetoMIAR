import { spawn } from 'node:child_process';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { Client } from 'pg';
import { parse } from 'dotenv';
const env = { ...process.env, ...parse(await readFile('.env')) };
const url = new URL(env.DATABASE_URL);
if (!['127.0.0.1', 'localhost'].includes(url.hostname))
  throw new Error('Testes são executados somente no banco local.');
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
env.API_TEST_URL = 'http://127.0.0.1:3301';
const server = spawn(process.execPath, ['dist/main.js'], {
  env,
  windowsHide: true,
  stdio: ['ignore', 'pipe', 'pipe'],
});
let logs = '';
server.stdout.on('data', (x) => (logs += x));
server.stderr.on('data', (x) => (logs += x));
const failure = spawn(process.execPath, ['dist/main.js'], {
  env: { ...env, PORT: '3302', IA_URL: 'http://127.0.0.1:1' },
  windowsHide: true,
  stdio: 'ignore',
});
env.API_FAILURE_URL = 'http://127.0.0.1:3302';
try {
  let ready = false;
  for (let i = 0; i < 60; i++) {
    try {
      const r = await fetch(env.API_TEST_URL + '/ocorrencias');
      if (r.status === 401) {
        ready = true;
        break;
      }
    } catch {}
    await new Promise((r) => setTimeout(r, 300));
  }
  if (!ready) throw new Error('API de teste não iniciou: ' + logs.slice(-1800));
  const test = spawn(process.execPath, ['--test', '--test-concurrency=1', 'test/fluxos.test.mjs', 'test/migracao-master.test.mjs', 'test/auditoria.test.mjs'], {
    env,
    windowsHide: true,
    stdio: ['inherit', 'pipe', 'pipe'],
  });
  let report = '';
  test.stdout.on('data', (x) => {
    process.stdout.write(x);
    report += x;
  });
  test.stderr.on('data', (x) => {
    process.stderr.write(x);
    report += x;
  });
  const code = await new Promise((r) => test.on('exit', r));
  const reportDir = process.env.TEST_REPORT_DIR ?? '../evidencias';
  await mkdir(reportDir, { recursive: true });
  await writeFile(resolve(reportDir, 'api-testes.txt'), report);
  process.exitCode = code;
} finally {
  server.kill();
  failure.kill();
}
