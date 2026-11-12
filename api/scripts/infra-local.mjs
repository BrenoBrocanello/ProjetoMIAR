import S3rver from 's3rver';
import {
  mkdir,
  readFile,
  writeFile,
  access,
  cp,
  unlink,
} from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { randomBytes, createHash } from 'node:crypto';
import { tmpdir } from 'node:os';
import { spawn } from 'node:child_process';
import { Client } from 'pg';

const root = resolve('..');
// initdb Windows não aceita caminho com acento em locale C: dados do PG em pasta ASCII.
const runtime =
  process.platform === 'win32'
    ? join(
        process.env.LOCALAPPDATA ?? tmpdir(),
        'MiarDev',
        createHash('sha256').update(root).digest('hex').slice(0, 10),
      )
    : join(root, '.runtime');
await mkdir(runtime, { recursive: true });
const envPath = resolve('.env');
let env;
try {
  env = await readFile(envPath, 'utf8');
} catch {
  const pass = randomBytes(24).toString('hex');
  const token = randomBytes(32).toString('hex');
  env = `PORT=3000\nDATABASE_URL=postgresql://miar:${pass}@127.0.0.1:55432/miar\nIA_URL=http://127.0.0.1:8001\nIA_TOKEN=${token}\nS3_ENDPOINT=http://127.0.0.1:9000\nS3_ACCESS_KEY=S3RVER\nS3_SECRET_KEY=S3RVER\nS3_BUCKET=miar-fotos\nSESSION_DIR=../.runtime/sessions\nMATCH_THRESHOLD=0.90\n`;
  await writeFile(envPath, env, { mode: 0o600, flag: 'wx' });
}
const config = Object.fromEntries(
  env
    .split(/\r?\n/)
    .filter((x) => x.includes('=') && !x.startsWith('#'))
    .map((x) => {
      const i = x.indexOf('=');
      return [x.slice(0, i), x.slice(i + 1)];
    }),
);
const url = new URL(config.DATABASE_URL);
const run = (file, args) =>
  new Promise((ok, no) => {
    const p = spawn(file, args, {
      windowsHide: true,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let err = '';
    p.stderr.on('data', (x) => (err += x));
    p.on('error', no);
    p.on('exit', (c) => (c === 0 ? ok() : no(new Error(err))));
  });
let stop;
if (process.platform === 'win32') {
  const native = resolve('node_modules/@embedded-postgres/windows-x64/native');
  const portable = join(runtime, 'pg16');
  try {
    await access(join(portable, 'bin', 'postgres.exe'));
  } catch {
    await cp(native, portable, { recursive: true });
  }
  const bin = join(portable, 'bin');
  const data = join(runtime, 'postgres');
  try {
    await access(join(data, 'PG_VERSION'));
  } catch {
    const pw = join(runtime, 'init-password');
    await writeFile(pw, decodeURIComponent(url.password), { mode: 0o600 });
    try {
      await run(join(bin, 'initdb.exe'), [
        '-D',
        data,
        '-U',
        decodeURIComponent(url.username),
        '--auth=scram-sha-256',
        '--encoding=UTF8',
        '--locale=C',
        `--pwfile=${pw}`,
      ]);
    } finally {
      await unlink(pw);
    }
  }
  await run(join(bin, 'pg_ctl.exe'), [
    '-D',
    data,
    '-l',
    join(runtime, 'postgres.log'),
    '-o',
    `-h 127.0.0.1 -p ${url.port}`,
    '-w',
    'start',
  ]);
  stop = () =>
    run(join(bin, 'pg_ctl.exe'), ['-D', data, '-m', 'fast', '-w', 'stop']);
} else {
  const { default: EmbeddedPostgres } = await import('embedded-postgres');
  const pg = new EmbeddedPostgres({
    databaseDir: join(runtime, 'postgres'),
    user: decodeURIComponent(url.username),
    password: decodeURIComponent(url.password),
    port: Number(url.port),
    persistent: true,
    autoRehydrateSymlinks: true,
  });
  try {
    await access(join(runtime, 'postgres', 'PG_VERSION'));
  } catch {
    await pg.initialise();
  }
  await pg.start();
  stop = () => pg.stop();
}
const admin = new Client({
  connectionString: config.DATABASE_URL.replace(/\/miar$/, '/postgres'),
});
await admin.connect();
if (
  !(await admin.query("SELECT 1 FROM pg_database WHERE datname='miar'"))
    .rowCount
)
  await admin.query('CREATE DATABASE miar');
await admin.end();
await mkdir(join(runtime, 'objetos'), { recursive: true });
const s3 = new S3rver({
  port: 9000,
  address: '127.0.0.1',
  directory: join(runtime, 'objetos'),
  silent: true,
});
await s3.run();
console.log(
  `MIAR: PostgreSQL 16 e S3 locais disponíveis. Dados persistentes: ${runtime}`,
);
let closing = false;
async function close() {
  if (closing) return;
  closing = true;
  await s3.close();
  await stop();
  process.exit(0);
}
process.on('SIGINT', close);
process.on('SIGTERM', close);
const stopFile = join(root, '.runtime', 'parar-infra');
setInterval(async () => {
  try {
    await access(stopFile);
    await unlink(stopFile);
    await close();
  } catch {}
}, 1000).unref();
