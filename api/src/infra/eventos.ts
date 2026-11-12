import { Global, Injectable, MessageEvent, Module } from '@nestjs/common';
import { Subject, merge, interval, map, Observable } from 'rxjs';

@Injectable()
export class Eventos {
  private readonly stream = new Subject<MessageEvent>();
  publicar(id: number) {
    this.stream.next({ data: { id_ocorrencia: id } });
  }
  assinar(): Observable<MessageEvent> {
    // Heartbeat mantém conexões móveis e proxies ativos; sem entidade de negócio adicional.
    return merge(
      this.stream,
      interval(25000).pipe(map(() => ({ data: { heartbeat: true } }))),
    );
  }
}
@Global()
@Module({ providers: [Eventos], exports: [Eventos] })
export class EventosModule {}
