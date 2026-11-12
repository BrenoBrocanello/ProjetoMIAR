import {
  BadRequestException,
  Controller,
  Get,
  Injectable,
  Param,
  ParseIntPipe,
  Res,
  ServiceUnavailableException,
} from '@nestjs/common';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import type { Response } from 'express';

// Interface técnica com serviço de mapas (§1.2.4), sem dados/entidades de negócio novos.
@Injectable()
export class MapaService {
  private readonly cache = resolve(
    process.env.MAP_CACHE_DIR ?? '../.runtime/mapa',
  );
  private readonly pending = new Map<string, Promise<Buffer>>();
  async tile(z: number, x: number, y: number): Promise<Buffer> {
    if (z < 0 || z > 19 || x < 0 || y < 0 || x >= 2 ** z || y >= 2 ** z)
      throw new BadRequestException('Coordenadas do mapa inválidas.');
    const key = `${z}-${x}-${y}`;
    if (this.pending.has(key)) return this.pending.get(key)!;
    const request = this.load(key, z, x, y).finally(() =>
      this.pending.delete(key),
    );
    this.pending.set(key, request);
    return request;
  }
  private async load(key: string, z: number, x: number, y: number) {
    await mkdir(this.cache, { recursive: true });
    const file = join(this.cache, key + '.png');
    const metadata = join(this.cache, key + '.json');
    let old: Buffer | undefined;
    try {
      old = await readFile(file);
      const meta = JSON.parse(await readFile(metadata, 'utf8'));
      if (meta.expires > Date.now()) return old;
    } catch {}
    try {
      const response = await fetch(
        `https://tile.openstreetmap.org/${z}/${x}/${y}.png`,
        {
          headers: { 'User-Agent': 'MIAR/1.0 (animal-rescue-mapping)' },
          signal: AbortSignal.timeout(10000),
        },
      );
      if (
        !response.ok ||
        !response.headers.get('content-type')?.startsWith('image/png')
      )
        throw new Error('Mapa indisponível');
      const bytes = Buffer.from(await response.arrayBuffer());
      if (bytes.length > 1024 * 1024) throw new Error('Tile inválido');
      const age = Number(
        response.headers.get('cache-control')?.match(/max-age=(\d+)/)?.[1] ??
          604800,
      );
      await writeFile(file, bytes);
      await writeFile(
        metadata,
        JSON.stringify({ expires: Date.now() + age * 1000 }),
      );
      return bytes;
    } catch {
      if (old) return old;
      throw new ServiceUnavailableException('Serviço de mapas indisponível.');
    }
  }
}
@Controller('mapa')
export class MapaController {
  constructor(private readonly mapa: MapaService) {}
  @Get(':z/:x/:y') async tile(
    @Param('z', ParseIntPipe) z: number,
    @Param('x', ParseIntPipe) x: number,
    @Param('y', ParseIntPipe) y: number,
    @Res() res: Response,
  ) {
    res
      .set({
        'Content-Type': 'image/png',
        'Cache-Control': 'public,max-age=3600',
        'X-Content-Type-Options': 'nosniff',
      })
      .send(await this.mapa.tile(z, x, y));
  }
}
