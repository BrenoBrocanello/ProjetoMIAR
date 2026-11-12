import 'dart:convert';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/entidades.dart';
import '../domain/miar_repository.dart';

const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

class Falha implements Exception {
  final String mensagem;
  final int? status;
  Falha(this.mensagem, [this.status]);
  @override
  String toString() => mensagem;
}

class ApiRepository implements MiarRepository {
  final Dio dio;
  final FlutterSecureStorage storage;
  void Function()? sessaoExpirada;
  ApiRepository({Dio? cliente, FlutterSecureStorage? armazenamento})
    : dio =
          cliente ??
          Dio(
            BaseOptions(
              baseUrl: apiUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 90),
              sendTimeout: const Duration(seconds: 60),
            ),
          ),
      storage = armazenamento ?? const FlutterSecureStorage() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) async {
          if (e.response?.statusCode == 401 &&
              e.requestOptions.headers['Authorization'] ==
                  dio.options.headers['Authorization'] &&
              !e.requestOptions.path.startsWith('/auth/login')) {
            dio.options.headers.remove('Authorization');
            await storage.delete(key: 'sessao');
            sessaoExpirada?.call();
          }
          handler.next(e);
        },
      ),
    );
  }
  Future<T> _request<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['message'] : null;
      throw Falha(
        message is String
            ? message
            : message is List
            ? 'Confira os campos informados e tente novamente.'
            : 'Não foi possível conectar ao MIAR. Verifique sua conexão e tente novamente.',
        e.response?.statusCode,
      );
    }
  }

  @override
  String fotoUrl(String caminho) => '${dio.options.baseUrl}$caminho';
  @override
  Stream<void> mudancas() {
    late StreamController<void> controller;
    CancelToken? cancel;
    bool encerrado = false;
    Future<void> conectar() async {
      while (!encerrado) {
        cancel = CancelToken();
        try {
          final response = await dio.get<ResponseBody>(
            '/ocorrencias/eventos',
            options: Options(
              responseType: ResponseType.stream,
              receiveTimeout: Duration.zero,
              headers: {'Accept': 'text/event-stream'},
            ),
            cancelToken: cancel,
          );
          await for (final line
              in response.data!.stream
                  .cast<List<int>>()
                  .transform(utf8.decoder)
                  .transform(const LineSplitter())) {
            if (encerrado) break;
            if (line.startsWith('data:') && !line.contains('heartbeat')) {
              controller.add(null);
            }
          }
        } catch (_) {
          /* Reconecta sem perder a consulta persistida no servidor. */
        }
        if (!encerrado) await Future<void>.delayed(const Duration(seconds: 3));
      }
    }

    controller = StreamController<void>(
      onListen: () => unawaited(conectar()),
      onCancel: () {
        encerrado = true;
        cancel?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<Usuario?> restaurarSessao() async {
    final token = await storage.read(key: 'sessao');
    if (token == null) return null;
    dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      return await _request(
        () async => Usuario(Json.from((await dio.get('/usuarios/me')).data)),
      );
    } on Falha catch (e) {
      if (e.status == 401) return null;
      rethrow;
    }
  }

  @override
  Future<Usuario> entrar(String email, String senha) => _request(() async {
    final data = (await dio.post(
      '/auth/login',
      data: {'email': email, 'senha': senha},
    )).data;
    await storage.write(key: 'sessao', value: data['token'] as String);
    dio.options.headers['Authorization'] = 'Bearer ${data['token']}';
    return Usuario(Json.from(data['usuario'] as Map));
  });
  @override
  Future<void> sair() => _request(() async {
    await dio.post('/auth/logout');
    await storage.delete(key: 'sessao');
    dio.options.headers.remove('Authorization');
  });
  @override
  Future<Usuario> cadastrar(Json dados) => _request(
    () async => Usuario(
      Json.from((await dio.post('/usuarios/cadastro', data: dados)).data),
    ),
  );
  @override
  Future<Usuario> atualizarPerfil(Json dados) => _request(
    () async =>
        Usuario(Json.from((await dio.patch('/usuarios/me', data: dados)).data)),
  );
  @override
  Future<PaginaOcorrencias> ocorrencias({
    Json filtros = const {},
    bool minhas = false,
    bool radar = false,
    int pagina = 0,
  }) => _request(() async {
    final data = (await dio.get(
      radar
          ? '/localizacoes/radar'
          : minhas
          ? '/ocorrencias/minhas'
          : '/ocorrencias',
      queryParameters: {...filtros, 'pagina': pagina},
    )).data;
    final items = (data['items'] as List)
        .map((o) => Ocorrencia(Json.from(o as Map)))
        .toList();
    if (radar) {
      var proxima = pagina + 1;
      while (items.length < data['total']) {
        final extra = (await dio.get(
          '/localizacoes/radar',
          queryParameters: {...filtros, 'pagina': proxima++},
        )).data;
        final lote = (extra['items'] as List)
            .map((o) => Ocorrencia(Json.from(o as Map)))
            .toList();
        if (lote.isEmpty) break;
        items.addAll(lote);
      }
    }
    return PaginaOcorrencias(items, data['total'] as int);
  });
  @override
  Future<Ocorrencia> ocorrencia(int id, {bool editar = false}) => _request(
    () async => Ocorrencia(
      Json.from(
        (await dio.get('/ocorrencias/$id${editar ? '/editar' : ''}')).data,
      ),
    ),
  );
  @override
  Future<Ocorrencia> salvarOcorrencia(
    Json dados,
    List<FotografiaEnvio> fotos, {
    int? id,
  }) => _request(() async {
    final form = FormData.fromMap({
      'dados': jsonEncode(dados),
      'fotos': fotos
          .map((f) => MultipartFile.fromBytes(f.bytes, filename: f.nome))
          .toList(),
    });
    final response = id == null
        ? await dio.post('/ocorrencias', data: form)
        : await dio.put('/ocorrencias/$id', data: form);
    return Ocorrencia(Json.from(response.data));
  });
  @override
  Future<Ocorrencia> alterarStatus(int id, String status) => _request(
    () async => Ocorrencia(
      Json.from(
        (await dio.patch(
          '/ocorrencias/$id/status',
          data: {'status_ocorrencia': status},
        )).data,
      ),
    ),
  );
  @override
  Future<void> excluir(int id) => _request(() async {
    await dio.delete('/ocorrencias/$id');
  });
  @override
  Future<Uri> contato(int id) => _request(
    () async =>
        Uri.parse((await dio.get('/contatos/$id')).data['url'] as String),
  );
  @override
  Future<List<Correspondencia>> correspondencias() => _request(
    () async => ((await dio.get('/correspondencias')).data as List)
        .map((c) => Correspondencia(Json.from(c as Map)))
        .toList(),
  );
  @override
  Future<Correspondencia> correspondencia(int id) => _request(
    () async => Correspondencia(
      Json.from((await dio.get('/correspondencias/$id')).data),
    ),
  );
  @override
  Future<void> confirmarAviso(int id) => _request(() async {
    await dio.post('/correspondencias/$id/notificacao-emitida');
  });
}
