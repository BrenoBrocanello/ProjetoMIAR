import {
  BadRequestException,
  Controller,
  Get,
  Injectable,
  Module,
  OnModuleInit,
  Param,
  Res,
  ServiceUnavailableException,
} from '@nestjs/common';
import {
  S3Client,
  CreateBucketCommand,
  HeadBucketCommand,
  PutObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
} from '@aws-sdk/client-s3';
import sharp from 'sharp';
import { randomUUID } from 'node:crypto';
import type { Response } from 'express';

export type FotoPreparada = { key: string; buffer: Buffer; vetor: number[] };
@Injectable()
export class FotosRepository implements OnModuleInit {
  private readonly bucket = process.env.S3_BUCKET ?? 'miar-fotos';
  private readonly s3 = new S3Client({
    endpoint: process.env.S3_ENDPOINT,
    region: 'us-east-1',
    forcePathStyle: true,
    credentials: {
      accessKeyId: process.env.S3_ACCESS_KEY ?? '',
      secretAccessKey: process.env.S3_SECRET_KEY ?? '',
    },
  });
  async onModuleInit() {
    if (
      !process.env.S3_ENDPOINT ||
      !process.env.S3_ACCESS_KEY ||
      !process.env.S3_SECRET_KEY
    )
      throw new Error('Configure o armazenamento S3.');
    try {
      await this.s3.send(new HeadBucketCommand({ Bucket: this.bucket }));
    } catch (error) {
      if (error.$metadata?.httpStatusCode === 404)
        await this.s3.send(new CreateBucketCommand({ Bucket: this.bucket }));
      else throw error;
    }
  }
  async put(key: string, buffer: Buffer) {
    await this.s3.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: buffer,
        ContentType: 'image/jpeg',
      }),
    );
  }
  async get(key: string) {
    const obj = await this.s3.send(
      new GetObjectCommand({ Bucket: this.bucket, Key: key }),
    );
    return Buffer.from(await obj.Body!.transformToByteArray());
  }
  async delete(key: string) {
    await this.s3.send(
      new DeleteObjectCommand({ Bucket: this.bucket, Key: key }),
    );
  }
}
@Injectable()
export class FotosService {
  constructor(readonly repo: FotosRepository) {}
  private readonly cache = new Map<string, number[]>();
  async descriptor(buffer: Buffer): Promise<number[]> {
    try {
      const response = await fetch(`${process.env.IA_URL}/descriptor`, {
        method: 'POST',
        headers: {
          'Content-Type': 'image/jpeg',
          Authorization: `Bearer ${process.env.IA_TOKEN}`,
        },
        body: new Uint8Array(buffer),
        signal: AbortSignal.timeout(20000),
      });
      if (!response.ok) throw new Error('IA indisponível');
      const result = await response.json();
      if (
        !Array.isArray(result.vetor) ||
        result.vetor.length !== 576 ||
        !result.vetor.every(Number.isFinite)
      )
        throw new Error('Descritor inválido');
      return result.vetor;
    } catch {
      throw new ServiceUnavailableException(
        'A análise de imagem está indisponível. A ocorrência não foi salva. Tente novamente.',
      );
    }
  }
  async preparar(files: Express.Multer.File[]): Promise<FotoPreparada[]> {
    if (!files?.length)
      throw new BadRequestException('Adicione pelo menos uma fotografia.');
    if (files.length > 6)
      throw new BadRequestException(
        'Envie até seis fotografias por ocorrência.',
      );
    const result: FotoPreparada[] = [];
    for (const f of files) {
      let buffer: Buffer;
      try {
        const im = sharp(f.buffer, {
          limitInputPixels: 40_000_000,
          failOn: 'error',
        });
        const meta = await im.metadata();
        if (
          !['jpeg', 'png', 'webp', 'heif'].includes(meta.format ?? '') ||
          (meta.width ?? 0) < 32 ||
          (meta.height ?? 0) < 32
        )
          throw new Error('Formato');
        buffer = await im
          .rotate()
          .resize({
            width: 1600,
            height: 1600,
            fit: 'inside',
            withoutEnlargement: true,
          })
          .jpeg({ quality: 85, mozjpeg: true })
          .toBuffer();
      } catch {
        throw new BadRequestException(
          'Uma fotografia não pôde ser lida. Use JPEG, PNG ou WebP válido.',
        );
      }
      result.push({
        key: `${randomUUID()}.jpg`,
        buffer,
        vetor: await this.descriptor(buffer),
      });
    }
    return result;
  }
  key(url: string) {
    const k = url.split('/').pop() ?? '';
    if (!/^[a-f0-9-]{36}\.jpg$/.test(k))
      throw new BadRequestException('Fotografia inválida.');
    return k;
  }
  async vetor(url: string) {
    const key = this.key(url);
    if (!this.cache.has(key))
      this.cache.set(key, await this.descriptor(await this.repo.get(key)));
    return this.cache.get(key)!;
  }
  async salvar(foto: FotoPreparada) {
    try {
      await this.repo.put(foto.key, foto.buffer);
      this.cache.set(foto.key, foto.vetor);
    } catch {
      throw new ServiceUnavailableException(
        'Não foi possível armazenar as fotografias. A ocorrência não foi salva.',
      );
    }
    return `/fotos/${foto.key}`;
  }
  async excluir(url: string) {
    const key = this.key(url);
    this.cache.delete(key);
    await this.repo.delete(key);
  }
}
@Controller('fotos')
export class FotosController {
  constructor(private readonly fotos: FotosService) {}
  @Get(':key') async get(@Param('key') key: string, @Res() res: Response) {
    const valid = this.fotos.key(key);
    try {
      const buffer = await this.fotos.repo.get(valid);
      res
        .set({
          'Content-Type': 'image/jpeg',
          'Cache-Control': 'public,max-age=86400',
          'X-Content-Type-Options': 'nosniff',
        })
        .send(buffer);
    } catch {
      res.status(404).json({ message: 'Fotografia indisponível.' });
    }
  }
}
@Module({
  providers: [FotosService, FotosRepository],
  controllers: [FotosController],
  exports: [FotosService],
})
export class FotosModule {}
