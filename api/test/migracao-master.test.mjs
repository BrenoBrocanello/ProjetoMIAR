import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdir, readFile, readdir, writeFile } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { Client } from 'pg';
import argon2 from 'argon2';

const original = new URL(process.env.DATABASE_URL);
if (
  !['127.0.0.1', 'localhost'].includes(original.hostname) ||
  !original.pathname.endsWith('_test')
)
  throw new Error('Teste de migração exige banco local isolado.');
const quote = (x) => '"' + x.replaceAll('"', '""') + '"';
const tag = Date.now().toString();
const dir = resolve('../.runtime/teste-migracao-' + tag);
await mkdir(dir, { recursive: true });
const fixture = await readFile('test/fixtures/modelo-anterior.json', 'utf8');
const fixtureFile = join(dir, 'modelo-anterior.json');
await writeFile(fixtureFile, fixture);
await writeFile(
  fixtureFile + '.sha256',
  createHash('sha256').update(fixture).digest('hex'),
);
function command(args, env) {
  const p = spawn(process.execPath, args, {
    env: { ...process.env, ...env },
    windowsHide: true,
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  let logs = '';
  p.stdout.on('data', (x) => (logs += x));
  p.stderr.on('data', (x) => (logs += x));
  return {
    p,
    done: new Promise((ok, fail) => {
      p.on('error', fail);
      p.on('exit', (code) => ok({ code, logs }));
    }),
  };
}
async function ready(port, proc) {
  for (let i = 0; i < 80; i++) {
    if (proc.p.exitCode !== null) throw new Error((await proc.done).logs);
    try {
      if (
        (await fetch('http://127.0.0.1:' + port + '/ocorrencias')).status ===
        401
      )
        return;
    } catch {}
    await new Promise((r) => setTimeout(r, 100));
  }
  throw new Error('API de migração não ficou disponível.');
}
await test('MASTER: migração preserva dados, backup é restaurável e falha reverte integralmente', async () => {
  const admin = new Client({ connectionString: process.env.DATABASE_URL });
  await admin.connect();
  const names = [];
  const clients = [];
  let api;
  async function create(label) {
    const name = 'miar_' + label + '_' + tag + '_test';
    names.push(name);
    await admin.query('CREATE DATABASE ' + quote(name));
    const url = new URL(original);
    url.pathname = '/' + name;
    const env = {
      DATABASE_URL: url.toString(),
      BACKUP_DIR: join(dir, 'backups'),
      CORRESPONDENCIAS_DIR: join(dir, 'resultados'),
      SESSION_DIR: join(dir, 'sessoes'),
      PORT: '3303',
    };
    const db = new Client({ connectionString: url.toString() });
    await db.connect();
    clients.push(db);
    return { db, env };
  }
  try {
    const main = await create('migracao');
    assert.equal(
      (
        await command(['scripts/restaurar-backup.mjs', fixtureFile], main.env)
          .done
      ).code,
      0,
    );
    const hash = await argon2.hash('Senha de migração!42');
    for (const [i, perfil] of [
      'Cidadão',
      'Protetor independente',
      'ONG',
    ].entries()) {
      const id = (
        await main.db.query(
          'INSERT INTO "USUARIO"(nome,email,senha,telefone,tipo_usuario) VALUES($1,$2,$3,$4,$5) RETURNING id_usuario',
          [
            'Pessoa ' + i,
            'migracao-' + i + '@example.test',
            hash,
            '11987654321',
            perfil,
          ],
        )
      ).rows[0].id_usuario;
      if (i === 0)
        await main.db.query('INSERT INTO "CIDADAO" VALUES($1,$2)', [
          id,
          '11122233344',
        ]);
      if (i === 1)
        await main.db.query('INSERT INTO "PROTETOR" VALUES($1,$2,$3)', [
          id,
          'Instituição anterior',
          '22233344455',
        ]);
      if (i === 2)
        await main.db.query('INSERT INTO "ONG" VALUES($1,$2,$3)', [
          id,
          'Nome anterior',
          '12345678000100',
        ]);
    }
    for (let i = 1; i <= 2; i++) {
      await main.db.query(
        'INSERT INTO "OCORRENCIA_ANIMAL"(id_usuario_responsavel,especie,porte,estado_saude,status_ocorrencia,descricao_fisica,data_registro) VALUES($1,$2,$3,$4,$5,$6,$7)',
        [
          i,
          'Cão',
          'Grande',
          'Saúde preservada',
          i === 1 ? 'Perdido' : 'Encontrado',
          'Descrição preservada',
          '2026-11-04T10:20:30Z',
        ],
      );
      await main.db.query(
        'INSERT INTO "LOCALIZACAC"(id_ocorrencia,latitude,longitude,cidade,endereco) VALUES($1,-23.18,-46.89,$2,$3)',
        [i, 'Jundiaí', 'Endereço preservado'],
      );
      await main.db.query(
        'INSERT INTO "FOTO"(id_ocorrencia,url_storage) VALUES($1,$2)',
        [i, '/fotos/migracao-' + i],
      );
      await main.db.query(
        'INSERT INTO "CONTATO"(id_ocorrencia,numero_whatsapp,permite_contato_publico) VALUES($1,$2,true)',
        [i, '11987654321'],
      );
    }
    await main.db.query(
      'INSERT INTO "CORRESPONDENCIA_IA"(id_ocorrencia_origem,id_ocorrencia_compativel,percentual_confianca) VALUES(2,1,97)',
    );
    api = command(['dist/main.js'], main.env);
    await ready(3303, api);
    const schema = JSON.parse(
      await readFile('database/schema-master.json', 'utf8'),
    );
    assert.deepEqual(
      (
        await main.db.query(
          "SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename",
        )
      ).rows.map((x) => x.tablename),
      Object.keys(schema).sort(),
    );
    const users = (
      await main.db.query('SELECT * FROM "USUARIO" ORDER BY id_usuario')
    ).rows;
    assert.deepEqual(
      users.map((x) => x.documento),
      ['11122233344', '22233344455', '12345678000100'],
    );
    assert(users.every((x) => x.senha === hash));
    assert.equal(
      Number(
        (await main.db.query('SELECT count(*) FROM "OCORRENCIA_ANIMAL"'))
          .rows[0].count,
      ),
      2,
    );
    assert.equal(
      (await main.db.query('SELECT nome FROM "CIDADE"')).rows[0].nome,
      'Jundiaí',
    );
    assert.equal(
      JSON.parse(
        (
          await main.db.query(
            'SELECT descricao FROM "OCORRENCIA_ANIMAL" LIMIT 1',
          )
        ).rows[0].descricao,
      ).estado_saude,
      'Saúde preservada',
    );
    assert.equal(
      (
        await main.db.query(
          'SELECT data_type FROM information_schema.columns WHERE table_name=$1 AND column_name=$2',
          ['FOTO', 'data_upload'],
        )
      ).rows[0].data_type,
      'date',
    );
    const login = await fetch('http://127.0.0.1:3303/auth/login', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        email: 'migracao-0@example.test',
        senha: 'Senha de migração!42',
      }),
    });
    assert.equal(login.status, 200);
    const token = (await login.json()).token;
    const headers = { Authorization: 'Bearer ' + token };
    const matches = await (
      await fetch('http://127.0.0.1:3303/correspondencias', { headers })
    ).json();
    assert.equal(matches.length, 1);
    assert.equal(matches[0].percentual_confianca, 97);
    await fetch(
      'http://127.0.0.1:3303/correspondencias/' +
        matches[0].id_correspondencia +
        '/notificacao-emitida',
      { method: 'POST', headers },
    );
    api.p.kill();
    await api.done;
    api = command(['dist/main.js'], main.env);
    await ready(3303, api);
    const persisted = await (
      await fetch('http://127.0.0.1:3303/correspondencias', { headers })
    ).json();
    assert.equal(persisted[0].status_notificacao, 'Emitida');
    const backupFiles = await readdir(main.env.BACKUP_DIR);
    const backup = join(
      main.env.BACKUP_DIR,
      backupFiles.find((x) => x.endsWith('.json')),
    );
    const restore = await create('restauracao');
    const restored = await command(
      ['scripts/restaurar-backup.mjs', backup],
      restore.env,
    ).done;
    assert.equal(restored.code, 0, restored.logs);
    assert.equal(
      (await restore.db.query('SELECT nome_fantasia FROM "ONG"')).rows[0]
        .nome_fantasia,
      'Nome anterior',
    );
    assert.equal(
      Number(
        (await restore.db.query('SELECT count(*) FROM "CORRESPONDENCIA_IA"'))
          .rows[0].count,
      ),
      1,
    );
    // Um destino não vazio é recusado, preservando os dados.
    assert.notEqual(
      (
        await command(['scripts/restaurar-backup.mjs', backup], restore.env)
          .done
      ).code,
      0,
    );
    api.p.kill();
    await api.done;
    api = undefined;
    // Um porte legado fora da enumeração impede a migração inteira, sem apagar registros.
    await restore.db.query('UPDATE "OCORRENCIA_ANIMAL" SET porte=$1', [
      'Porte fora do modelo',
    ]);
    const invalid = command(['dist/main.js'], restore.env);
    const failed = await invalid.done;
    assert.notEqual(failed.code, 0);
    assert.equal(
      (await restore.db.query('SELECT porte FROM "OCORRENCIA_ANIMAL" LIMIT 1'))
        .rows[0].porte,
      'Porte fora do modelo',
    );
    assert.equal(
      (
        await restore.db.query(
          "SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='CIDADAO'",
        )
      ).rowCount,
      1,
    );
    assert.equal(
      (
        await restore.db.query(
          "SELECT 1 FROM information_schema.schemata WHERE schema_name='miar_antes_master'",
        )
      ).rowCount,
      0,
    );
    console.log(
      'Migração com dados, restauração verificada, persistência após reinício e rollback: OK.',
    );
  } finally {
    if (api) {
      api.p.kill();
      await api.done;
    }
    for (const db of clients) await db.end();
    for (const name of names) {
      assert(/^miar_(migracao|restauracao)_\d+_test$/.test(name));
      await admin.query('DROP DATABASE ' + quote(name));
    }
    await admin.end();
  }
});
