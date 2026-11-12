import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { Client } from 'pg';

const base = process.env.API_TEST_URL;
if (!base || !new URL(process.env.DATABASE_URL).pathname.endsWith('_test'))
  throw new Error('Requer ambiente isolado de teste.');
const db = new Client({ connectionString: process.env.DATABASE_URL });
const ids = [];
const occs = [];
const tag = Date.now().toString();
const photo = await readFile(
  '../prototipos/assets/img/ocorrencia-cao-grande.jpg',
);
const outra = await readFile(
  '../prototipos/assets/img/ocorrencia-gato-filhote.jpg',
);
async function req(path, { token, method = 'GET', data, raw } = {}) {
  const response = await fetch(base + path, {
    method,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(data ? { 'Content-Type': 'application/json' } : {}),
    },
    body: raw ?? (data ? JSON.stringify(data) : undefined),
  });
  const result = response.status === 204 ? null : await response.json();
  return { status: response.status, body: result };
}
const dados = (extra = {}) => ({
  especie: 'Cão',
  porte: 'Grande',
  estado_saude: 'Saudável',
  status_ocorrencia: 'Perdido',
  descricao_fisica: 'Pelagem caramelo, coleira azul',
  localizacao: {
    latitude: -23.185,
    longitude: -46.898,
    cidade: 'Jundiaí',
    endereco: 'Local de teste',
  },
  numero_whatsapp: '11987654321',
  ...extra,
});
async function salvar(token, data, fotos = [photo], id) {
  const form = new FormData();
  form.append('dados', JSON.stringify(data));
  for (const f of fotos)
    form.append('fotos', new Blob([f], { type: 'image/jpeg' }), 'foto.jpg');
  return req('/ocorrencias' + (id ? '/' + id : ''), {
    token,
    method: id ? 'PUT' : 'POST',
    raw: form,
  });
}
await test('MIAR: fluxos documentados com PostgreSQL, S3 e rede neural reais', async (t) => {
  await db.connect();
  let a, b, c, perdido, encontrado;
  try {
    await t.test(
      'CU01: cadastro dos três perfis com documento centralizado, sem senha no retorno',
      async () => {
        for (const [i, tipo] of [
          'Cidadão',
          'Protetor independente',
          'ONG',
        ].entries()) {
          const data = {
            nome: 'Usuário de teste ' + i,
            email: `miar-${tag}-${i}@example.test`,
            senha: 'Senha de teste!42',
            telefone: '11987654321',
            tipo_usuario: tipo,
            documento: i === 2 ? '12345678000100' : '12345678900',
          };
          const r = await req('/usuarios/cadastro', { method: 'POST', data });
          assert.equal(r.status, 201, JSON.stringify(r.body));
          assert.equal(r.body.senha, undefined);
          assert.equal(r.body.documento, data.documento);
          assert.equal(r.body.cpf, undefined);
          assert.equal(r.body.nome_fantasia, undefined);
          ids.push(r.body.id_usuario);
          const login = await req('/auth/login', {
            method: 'POST',
            data: { email: data.email, senha: data.senha },
          });
          assert.equal(login.status, 200);
          if (i === 0) a = login.body;
          else if (i === 1) b = login.body;
          else c = login.body;
        }
        const hashes = await db.query(
          'SELECT senha FROM "USUARIO" WHERE id_usuario=ANY($1::int[])',
          [ids],
        );
        assert(hashes.rows.every((x) => x.senha.startsWith('$argon2id$')));
      },
    );
    await t.test(
      'CU01: DDD inválido e campo fora do escopo são rejeitados',
      async () => {
        const r = await req('/usuarios/cadastro', {
          method: 'POST',
          data: {
            nome: 'X',
            email: `inv-${tag}@example.test`,
            senha: 'x',
            telefone: '00123456789',
            tipo_usuario: 'Cidadão',
            documento: '123',
          },
        });
        assert.equal(r.status, 400);
        const p = await req('/usuarios/me', {
          method: 'PATCH',
          token: a.token,
          data: { tipo_usuario: 'ONG' },
        });
        assert.equal(p.status, 400);
      },
    );
    await t.test(
      'CU02: credenciais incorretas e acesso sem token são negados',
      async () => {
        assert.equal(
          (
            await req('/auth/login', {
              method: 'POST',
              data: { email: a.usuario.email, senha: 'incorreta' },
            })
          ).status,
          401,
        );
        assert.equal((await req('/ocorrencias')).status, 401);
      },
    );
    await t.test(
      'RF01: consulta e atualização dos próprios dados',
      async () => {
        const r = await req('/usuarios/me', {
          token: a.token,
          method: 'PATCH',
          data: { nome: 'Cidadão atualizado', telefone: '(11) 99876-5432' },
        });
        assert.equal(r.status, 200);
        assert.equal(r.body.nome, 'Cidadão atualizado');
        assert.equal(r.body.telefone, '11998765432');
      },
    );
    await t.test(
      'CU05: cadastro com imagem e localização, análise executada e foto otimizada',
      async () => {
        const r = await salvar(a.token, dados());
        assert.equal(r.status, 201, JSON.stringify(r.body));
        perdido = r.body;
        occs.push(perdido.id_ocorrencia);
        assert.equal(perdido.fotos.length, 1);
        const stored = await fetch(base + perdido.fotos[0].url_storage);
        assert.equal(stored.status, 200);
        assert.equal(stored.headers.get('content-type'), 'image/jpeg');
        assert((await stored.arrayBuffer()).byteLength < photo.byteLength);
      },
    );
    await t.test(
      'CU05: foto ausente, imagem inválida, status e coordenadas inválidos não persistem',
      async () => {
        const antes = Number(
          (await db.query('SELECT count(*) FROM "OCORRENCIA_ANIMAL"')).rows[0]
            .count,
        );
        for (const [d, f] of [
          [dados(), []],
          [dados(), [Buffer.from('imagem inválida')]],
          [dados({ status_ocorrencia: 'Inventado' }), [photo]],
          [
            dados({
              localizacao: { cidade: 'Jundiaí', latitude: 100, longitude: 0 },
            }),
            [photo],
          ],
          [
            dados({ localizacao: { cidade: '', latitude: 0, longitude: 0 } }),
            [photo],
          ],
        ])
          assert.equal((await salvar(a.token, d, f)).status, 400);
        assert.equal(
          Number(
            (await db.query('SELECT count(*) FROM "OCORRENCIA_ANIMAL"')).rows[0]
              .count,
          ),
          antes,
        );
      },
    );
    await t.test(
      'CU11/CU12: outra ocorrência com mesma imagem gera possível correspondência para o responsável perdido',
      async () => {
        const r = await salvar(
          b.token,
          dados({ status_ocorrencia: 'Encontrado' }),
        );
        assert.equal(r.status, 201, JSON.stringify(r.body));
        encontrado = r.body;
        occs.push(encontrado.id_ocorrencia);
        const matches = await req('/correspondencias', { token: a.token });
        assert.equal(matches.status, 200);
        assert.equal(matches.body.length, 1);
        assert(matches.body[0].percentual_confianca > 99);
        assert.equal(matches.body[0].status_notificacao, 'Pendente');
        const id = matches.body[0].id_correspondencia;
        const detail = await req('/correspondencias/' + id, { token: a.token });
        assert.equal(detail.status, 200);
        assert.equal(detail.body.perdido.id_ocorrencia, perdido.id_ocorrencia);
        assert.equal(
          (await req('/correspondencias/' + id, { token: b.token })).status,
          404,
        );
        assert.equal(
          (
            await req(`/correspondencias/${id}/notificacao-emitida`, {
              token: a.token,
              method: 'POST',
            })
          ).status,
          201,
        );
      },
    );
    await t.test(
      'CU11: fotografia diferente não produz correspondência fictícia',
      async () => {
        const r = await salvar(
          c.token,
          dados({ status_ocorrencia: 'Encontrado' }),
          [outra],
        );
        assert.equal(r.status, 201);
        occs.push(r.body.id_ocorrencia);
        const matches = await req('/correspondencias', { token: a.token });
        assert.equal(matches.body.length, 1);
      },
    );
    await t.test(
      'CU05/RNF03: indisponibilidade da IA não confirma nem persiste cadastro',
      async () => {
        const count = Number(
          (await db.query('SELECT count(*) FROM "OCORRENCIA_ANIMAL"')).rows[0]
            .count,
        );
        const form = new FormData();
        form.append('dados', JSON.stringify(dados()));
        form.append(
          'fotos',
          new Blob([photo], { type: 'image/jpeg' }),
          'foto.jpg',
        );
        const response = await fetch(
          process.env.API_FAILURE_URL + '/ocorrencias',
          {
            method: 'POST',
            headers: { Authorization: `Bearer ${a.token}` },
            body: form,
          },
        );
        assert.equal(response.status, 503);
        assert.equal(
          Number(
            (await db.query('SELECT count(*) FROM "OCORRENCIA_ANIMAL"')).rows[0]
              .count,
          ),
          count,
        );
      },
    );
    await t.test(
      'CU03/CU04: filtros por status, espécie, porte, cidade e resultado vazio',
      async () => {
        const r = await req(
          '/ocorrencias?status=Perdido&especie=C%C3%A3o&porte=Grande&cidade=Jundia%C3%AD',
          { token: a.token },
        );
        assert.equal(r.status, 200);
        assert(
          r.body.items.some((x) => x.id_ocorrencia === perdido.id_ocorrencia),
        );
        assert.equal(
          (
            await req('/ocorrencias?cidade=CidadeInexistente', {
              token: a.token,
            })
          ).body.total,
          0,
        );
      },
    );
    await t.test('CU09: radar respeita os atores do diagrama', async () => {
      assert.equal(
        (await req('/localizacoes/radar', { token: a.token })).status,
        403,
      );
      for (const u of [b, c]) {
        const r = await req('/localizacoes/radar', { token: u.token });
        assert.equal(r.status, 200);
        assert(
          r.body.items.some((x) => x.id_ocorrencia === perdido.id_ocorrencia),
        );
      }
    });
    await t.test(
      'RD04/RNF05: usuário não altera, exclui ou edita ocorrência de terceiro',
      async () => {
        const id = perdido.id_ocorrencia;
        assert.equal(
          (
            await req(`/ocorrencias/${id}/status`, {
              token: b.token,
              method: 'PATCH',
              data: { status_ocorrencia: 'Adotado' },
            })
          ).status,
          403,
        );
        assert.equal(
          (
            await req(`/ocorrencias/${id}`, {
              token: b.token,
              method: 'DELETE',
            })
          ).status,
          403,
        );
        assert.equal(
          (await req(`/ocorrencias/${id}/editar`, { token: b.token })).status,
          403,
        );
        assert.equal((await salvar(b.token, dados(), [photo], id)).status, 403);
      },
    );
    await t.test(
      'CU07/CU10: contato é removido da resposta pública para ambos os status finais',
      async () => {
        const id = encontrado.id_ocorrencia;
        assert.equal(
          (await req('/contatos/' + id, { token: a.token })).body.url,
          'https://wa.me/5511987654321',
        );
        for (const status of ['Adotado', 'Resgatado']) {
          assert.equal(
            (
              await req(`/ocorrencias/${id}/status`, {
                token: b.token,
                method: 'PATCH',
                data: { status_ocorrencia: status },
              })
            ).status,
            200,
          );
          const o = (await req('/ocorrencias/' + id, { token: a.token })).body;
          assert.equal(o.contato, null);
          assert.equal(JSON.stringify(o).includes('11987654321'), false);
          assert.equal(
            (await req('/contatos/' + id, { token: a.token })).status,
            410,
          );
        }
      },
    );
    await t.test(
      'RF02: cidadão altera os próprios dados e preserva fotos na edição',
      async () => {
        const r = await salvar(
          a.token,
          dados({
            descricao_fisica: 'Descrição atualizada',
            fotos_mantidas: perdido.fotos.map((f) => f.id_foto),
          }),
          [],
          perdido.id_ocorrencia,
        );
        assert.equal(r.status, 200, JSON.stringify(r.body));
        assert.equal(r.body.descricao_fisica, 'Descrição atualizada');
        assert.equal(r.body.fotos.length, 1);
      },
    );
    await t.test(
      'RD07: análise também compara ocorrências diferentes do mesmo responsável',
      async () => {
        const r = await salvar(
          a.token,
          dados({ status_ocorrencia: 'Encontrado' }),
        );
        assert.equal(r.status, 201, JSON.stringify(r.body));
        occs.push(r.body.id_ocorrencia);
        const matches = await req('/correspondencias', { token: a.token });
        assert(
          matches.body.some(
            (x) =>
              x.id_ocorrencia_origem === r.body.id_ocorrencia &&
              x.id_ocorrencia_compativel === perdido.id_ocorrencia,
          ),
        );
      },
    );
    await t.test(
      'CU08: exclusão remove ocorrência, relacionamentos e foto armazenada',
      async () => {
        const id = encontrado.id_ocorrencia;
        assert.equal(
          (
            await req('/ocorrencias/' + id, {
              token: b.token,
              method: 'DELETE',
            })
          ).status,
          200,
        );
        assert.equal(
          (await req('/ocorrencias/' + id, { token: a.token })).status,
          404,
        );
        assert.equal(
          (await fetch(base + encontrado.fotos[0].url_storage)).status,
          404,
        );
      },
    );
    await t.test(
      'Atualizações são publicadas em tempo real somente após a gravação',
      async () => {
        const ctrl = new AbortController();
        const response = await fetch(base + '/ocorrencias/eventos', {
          headers: { Authorization: `Bearer ${a.token}` },
          signal: ctrl.signal,
        });
        assert.equal(response.status, 200);
        assert(
          response.headers.get('content-type').includes('text/event-stream'),
        );
        const reader = response.body.getReader();
        const received = (async () => {
          let text = '';
          while (!text.includes('id_ocorrencia')) {
            const { value, done } = await reader.read();
            if (done) break;
            text += new TextDecoder().decode(value);
          }
          return text;
        })();
        const change = await req(
          `/ocorrencias/${perdido.id_ocorrencia}/status`,
          {
            token: a.token,
            method: 'PATCH',
            data: { status_ocorrencia: 'Perdido' },
          },
        );
        assert.equal(change.status, 200);
        const timeout = setTimeout(() => ctrl.abort(), 2000);
        try {
          const text = await received;
          assert(text.includes(`"id_ocorrencia":${perdido.id_ocorrencia}`));
        } finally {
          clearTimeout(timeout);
          ctrl.abort();
        }
      },
    );
    await t.test(
      'Modelo físico preserva exatamente as nove entidades e os atributos do DER',
      async () => {
        const expected = JSON.parse(
          await readFile('database/schema-master.json', 'utf8'),
        );
        const tables = (
          await db.query(
            "SELECT tablename FROM pg_tables WHERE schemaname='public' AND tablename <> 'spatial_ref_sys' ORDER BY tablename",
          )
        ).rows.map((r) => r.tablename);
        assert.deepEqual(tables, Object.keys(expected).sort());
        for (const [table, columns] of Object.entries(expected)) {
          const actual = (
            await db.query(
              "SELECT column_name,data_type FROM information_schema.columns WHERE table_schema='public' AND table_name=$1",
              [table],
            )
          ).rows;
          assert.deepEqual(
            Object.fromEntries(actual.map((c) => [c.column_name, c.data_type])),
            columns,
            table + ' colunas/tipos',
          );
        }
        const keys = (
          await db.query(`SELECT t.relname AS tabela,c.contype AS tipo,pg_get_constraintdef(c.oid) AS definition
          FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace
          WHERE n.nspname='public' AND c.contype IN ('p','f','u')`)
        ).rows;
        assert.equal(keys.filter((k) => k.tipo === 'p').length, 9);
        const fks = keys
          .filter((k) => k.tipo === 'f')
          .map(
            (k) => k.tabela + ':' + k.definition.replace(/ ON DELETE.*$/, ''),
          )
          .sort();
        assert.deepEqual(
          fks,
          [
            'ANIMAL:FOREIGN KEY (id_especie) REFERENCES "ESPECIE"(id_especie)',
            'OCORRENCIA_ANIMAL:FOREIGN KEY (id_usuario_responsavel) REFERENCES "USUARIO"(id_usuario)',
            'OCORRENCIA_ANIMAL:FOREIGN KEY (id_animal) REFERENCES "ANIMAL"(id_animal)',
            'LOCALIZACAC:FOREIGN KEY (id_ocorrencia) REFERENCES "OCORRENCIA_ANIMAL"(id_ocorrencia)',
            'LOCALIZACAC:FOREIGN KEY (id_cidade) REFERENCES "CIDADE"(id_cidade)',
            'FOTO:FOREIGN KEY (id_ocorrencia) REFERENCES "OCORRENCIA_ANIMAL"(id_ocorrencia)',
            'CONTATO:FOREIGN KEY (id_ocorrencia) REFERENCES "OCORRENCIA_ANIMAL"(id_ocorrencia)',
            'MENSAGEM_WHATSAPP:FOREIGN KEY (id_contato) REFERENCES "CONTATO"(id_contato)',
          ].sort(),
        );
        assert(
          keys.some(
            (k) =>
              k.tabela === 'LOCALIZACAC' &&
              k.tipo === 'u' &&
              k.definition === 'UNIQUE (id_ocorrencia)',
          ),
        );
        assert(!keys.some((k) => k.tabela === 'CONTATO' && k.tipo === 'u'));
      },
    );
    await t.test(
      'DER: animal compartilhável, vários contatos/mensagens e localização única',
      async () => {
        await db.query('BEGIN');
        try {
          const current = (
            await db.query(
              'SELECT * FROM "OCORRENCIA_ANIMAL" WHERE id_ocorrencia=$1',
              [perdido.id_ocorrencia],
            )
          ).rows[0];
          const extra = (
            await db.query(
              'INSERT INTO "OCORRENCIA_ANIMAL"(id_usuario_responsavel,id_animal,status_ocorrencia,descricao) VALUES($1,$2,$3,$4) RETURNING id_ocorrencia',
              [ids[0], current.id_animal, 'Encontrado', 'Teste relacional'],
            )
          ).rows[0].id_ocorrencia;
          assert(extra > 0);
          const contact = (
            await db.query(
              'INSERT INTO "CONTATO"(id_ocorrencia,numero_whatsapp,whatsapp_link) VALUES($1,$2,$3) RETURNING id_contato',
              [
                perdido.id_ocorrencia,
                '11998765432',
                'https://wa.me/5511998765432',
              ],
            )
          ).rows[0].id_contato;
          for (let i = 0; i < 2; i++)
            await db.query(
              'INSERT INTO "MENSAGEM_WHATSAPP"(id_contato,texto,remetente) VALUES($1,$2,$3)',
              [contact, 'Fixture de cardinalidade', 'teste'],
            );
          assert.equal(
            Number(
              (
                await db.query(
                  'SELECT count(*) FROM "MENSAGEM_WHATSAPP" WHERE id_contato=$1',
                  [contact],
                )
              ).rows[0].count,
            ),
            2,
          );
        } finally {
          await db.query('ROLLBACK');
        }
      },
    );

    await t.test(
      'RNF02: consulta e filtros locais abaixo de dois segundos',
      async () => {
        const tempos = [];
        for (let i = 0; i < 5; i++) {
          const start = performance.now();
          assert.equal(
            (await req('/ocorrencias?status=Perdido', { token: a.token }))
              .status,
            200,
          );
          tempos.push(Math.round(performance.now() - start));
        }
        assert(Math.max(...tempos) < 2000);
        console.log('Consultas locais (ms):', tempos.join(', '));
      },
    );
    await t.test(
      'CU02: logout revoga efetivamente o token no servidor',
      async () => {
        assert.equal(
          (await req('/auth/logout', { token: a.token, method: 'POST' }))
            .status,
          204,
        );
        assert.equal(
          (await req('/usuarios/me', { token: a.token })).status,
          401,
        );
      },
    );
  } finally {
    // Somente IDs produzidos por esta execução em banco *_test.
    if (a?.usuario) {
      const fresh = await req('/auth/login', {
        method: 'POST',
        data: { email: a.usuario.email, senha: 'Senha de teste!42' },
      });
      if (fresh.status === 200) a = fresh.body;
    }
    for (const id of occs) {
      const row = (
        await db.query(
          'SELECT id_usuario_responsavel FROM "OCORRENCIA_ANIMAL" WHERE id_ocorrencia=$1',
          [id],
        )
      ).rows[0];
      const owner = [a, b, c].find(
        (u) => u?.usuario.id_usuario === row?.id_usuario_responsavel,
      );
      if (owner?.token)
        await req('/ocorrencias/' + id, {
          token: owner.token,
          method: 'DELETE',
        });
    }
    for (const u of [a, b, c])
      if (u?.token)
        await req('/auth/logout', { token: u.token, method: 'POST' });
    if (ids.length) {
      await db.query(
        'DELETE FROM "OCORRENCIA_ANIMAL" WHERE id_usuario_responsavel=ANY($1::int[])',
        [ids],
      );
      await db.query('DELETE FROM "USUARIO" WHERE id_usuario=ANY($1::int[])', [
        ids,
      ]);
    }
    await db.end();
  }
});
