import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miar/domain/entidades.dart';
import 'auditoria_widget_test.dart';
import 'fluxos_widget_test.dart' as base;

class Headers extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class Response extends Stream<List<int>> implements HttpClientResponse {
  final bool ok;
  final Uint8List bytes;
  Response(this.ok, this.bytes);
  @override
  int get statusCode => ok ? 200 : 503;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class Request extends Fake implements HttpClientRequest {
  final Client owner;
  Request(this.owner);
  @override
  HttpHeaders get headers => Headers();
  @override
  Future<HttpClientResponse> close() async => Response(owner.ok, owner.bytes);
}

class Client extends Fake implements HttpClient {
  bool ok = false;
  int calls = 0;
  final bytes = File('test/fixtures/mapa-1px.png').readAsBytesSync();
  @override
  set autoUncompress(bool value) {}
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    calls++;
    return Request(this);
  }
}

class Repo extends RepositorioAuditoria {
  final events = StreamController<void>.broadcast();
  String current = 'Perdido';
  bool excluido = false;
  @override
  Stream<void> mudancas() => events.stream;
  @override
  Future<PaginaOcorrencias> ocorrencias({
    Json filtros = const {},
    bool minhas = false,
    bool radar = false,
    int pagina = 0,
  }) async => PaginaOcorrencias([
    if (!excluido)
      Ocorrencia({...registro.dados, 'status_ocorrencia': current}),
  ], excluido ? 0 : 1);
}

void main() {
  testWidgets(
    'RF04/RNF03: tentar novamente recarrega mapa; resumo acompanha status e exclusão',
    (tester) async {
      final client = Client();
      debugNetworkImageHttpClientProvider = () => client;
      addTearDown(() => debugNetworkImageHttpClientProvider = null);
      final repo = Repo()..atual = base.usuario('ONG');
      final sessao = await base.montar(tester, repo);
      Future<void> carregarImagens() async {
        for (var i = 0; i < 30; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await tester.tap(find.text('Radar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Não foi possível carregar o mapa. Verifique sua conexão.'),
        findsOneWidget,
      );
      final failed = client.calls;
      client.ok = true;
      await tester.tap(find.text('Tentar novamente'));
      await carregarImagens();
      expect(
        client.calls,
        greaterThan(failed),
        reason: 'Nova tentativa deve buscar as imagens que falharam.',
      );
      final marker = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Cão, Perdido, Jundiaí',
      );
      await tester.tap(marker);
      await carregarImagens();
      expect(find.text('Perdido'), findsNWidgets(2));
      repo.current = 'Emergência';
      repo.events.add(null);
      await tester.pumpAndSettle();
      expect(
        find.text('Emergência'),
        findsNWidgets(2),
        reason: 'O resumo selecionado precisa mostrar o novo status.',
      );
      expect(find.text('Perdido'), findsOneWidget);
      repo.excluido = true;
      repo.events.add(null);
      await tester.pumpAndSettle();
      expect(
        find.text('Emergência'),
        findsOneWidget,
        reason: 'Só o filtro deve permanecer, sem resumo de registro excluído.',
      );
      expect(marker, findsNothing);
      await tester.pumpWidget(const SizedBox());
      sessao.dispose();
      await repo.events.close();
      debugNetworkImageHttpClientProvider = null;
    },
  );
}
