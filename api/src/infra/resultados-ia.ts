import { createHash, randomInt, randomUUID } from 'node:crypto';
import {
  mkdir,
  readFile,
  readdir,
  rename,
  unlink,
  writeFile,
} from 'node:fs/promises';
import { join, resolve } from 'node:path';

export interface ResultadoIA {
  id_correspondencia: number;
  id_ocorrencia_origem: number;
  id_ocorrencia_compativel: number;
  percentual_confianca: number;
  data_analise: string;
  status_notificacao: string;
  assinatura_origem?: string;
  assinatura_compativel?: string;
}
// Estado técnico da análise exigida por CU11/CU12. Não cria tabela fora do DER.
// Cada arquivo é publicado por rename, sob trava transacional da ocorrência.
export class ResultadosIA {
  readonly dir: string;
  constructor() {
    const url = new URL(process.env.DATABASE_URL!);
    const key = createHash('sha256')
      .update(url.host + url.pathname)
      .digest('hex')
      .slice(0, 16);
    this.dir = resolve(
      process.env.CORRESPONDENCIAS_DIR ?? '../.runtime/correspondencias',
      key,
    );
  }
  async todos(): Promise<ResultadoIA[]> {
    await mkdir(this.dir, { recursive: true, mode: 0o700 });
    const rows: ResultadoIA[] = [];
    for (const file of await readdir(this.dir)) {
      if (!/^\d+\.json$/.test(file)) continue;
      rows.push(...JSON.parse(await readFile(join(this.dir, file), 'utf8')));
    }
    return rows;
  }
  async gravar(origem: number, rows: ResultadoIA[]) {
    await mkdir(this.dir, { recursive: true, mode: 0o700 });
    const file = join(this.dir, origem + '.json');
    const tmp = file + '.' + randomUUID() + '.tmp';
    await writeFile(tmp, JSON.stringify(rows), { mode: 0o600, flag: 'wx' });
    try {
      await rename(tmp, file);
    } finally {
      await unlink(tmp).catch(() => {});
    }
  }
  async substituir(
    origem: number,
    rows: Omit<ResultadoIA, 'id_correspondencia'>[],
  ) {
    const previous = (await this.todos()).filter(
      (x) => x.id_ocorrencia_origem === origem,
    );
    const occupied = new Set(
      (await this.todos()).map((x) => x.id_correspondencia),
    );
    const result = rows.map((row) => {
      let id: number;
      do {
        id = randomInt(1, 2147483647);
      } while (occupied.has(id));
      occupied.add(id);
      return { ...row, id_correspondencia: id };
    });
    await this.gravar(origem, result);
    return async () => this.gravar(origem, previous);
  }
  async importar(rows: ResultadoIA[]) {
    for (const origem of new Set(rows.map((x) => x.id_ocorrencia_origem))) {
      await this.gravar(
        origem,
        rows.filter((x) => x.id_ocorrencia_origem === origem),
      );
    }
  }
}
