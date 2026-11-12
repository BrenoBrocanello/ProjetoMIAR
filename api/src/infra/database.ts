import {
  Global,
  Injectable,
  Logger,
  Module,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { Pool, PoolClient } from 'pg';
import { prepararMaster } from './migrar-master';

@Injectable()
export class Database implements OnModuleInit, OnModuleDestroy {
  readonly pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    max: 12,
    connectionTimeoutMillis: 5000,
    statement_timeout: 15000,
  });
  hasVector = false;
  async onModuleInit() {
    if (!process.env.DATABASE_URL)
      throw new Error('DATABASE_URL não configurada.');
    const connection = await this.pool.connect();
    try {
      const backup = await prepararMaster(connection);
      if (backup)
        new Logger(Database.name).log(
          'Migração MASTER concluída. Backup: ' + backup,
        );
    } finally {
      connection.release();
    }
    const ext = await this.pool.query(
      "SELECT name FROM pg_available_extensions WHERE name IN ('vector','postgis')",
    );
    for (const { name } of ext.rows) {
      await this.pool.query(`CREATE EXTENSION IF NOT EXISTS ${name}`);
      if (name === 'vector') this.hasVector = true;
      if (name === 'postgis')
        await this.pool.query(
          'CREATE INDEX IF NOT EXISTS localizacao_geo ON "LOCALIZACAC" USING gist (ST_SetSRID(ST_MakePoint(longitude,latitude),4326))',
        );
    }
  }
  async transaction<T>(fn: (db: PoolClient) => Promise<T>): Promise<T> {
    const db = await this.pool.connect();
    try {
      await db.query('BEGIN');
      const result = await fn(db);
      await db.query('COMMIT');
      return result;
    } catch (error) {
      await db.query('ROLLBACK');
      throw error;
    } finally {
      db.release();
    }
  }
  async onModuleDestroy() {
    await this.pool.end();
  }
}
@Global()
@Module({ providers: [Database], exports: [Database] })
export class DatabaseModule {}
