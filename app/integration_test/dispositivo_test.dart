import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:miar/data/api_repository.dart';
import 'package:miar/data/notificacoes.dart';
import 'package:miar/domain/entidades.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('GPS, compressão e notificação usam serviços nativos reais', (
    tester,
  ) async {
    if (!apiUrl.endsWith(':3301')) {
      throw StateError('Requer API isolada de teste.');
    }
    var permission = await Geolocator.checkPermission();
    for (var i = 0; i < 40 && permission == LocationPermission.denied; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      permission = await Geolocator.checkPermission();
    }
    expect(
      [
        LocationPermission.always,
        LocationPermission.whileInUse,
      ].contains(permission),
      isTrue,
      reason: 'Conceda localização ao pacote de teste com adb.',
    );
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 25),
      ),
    );
    expect(position.latitude.abs(), lessThanOrEqualTo(90));
    expect(position.longitude.abs(), lessThanOrEqualTo(180));
    final animal = (await rootBundle.load(
      'assets/img/hero-cao-gato.jpg',
    )).buffer.asUint8List();
    final compressed = await FlutterImageCompress.compressWithList(
      animal,
      minWidth: 1600,
      minHeight: 1600,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    expect(compressed.length, lessThan(animal.length));
    final tag = DateTime.now().millisecondsSinceEpoch;
    final http = Dio(BaseOptions(baseUrl: apiUrl));
    final email = 'notificacao-$tag@example.test',
        senha = 'Teste dispositivo!42';
    await http.post(
      '/usuarios/cadastro',
      data: {
        'nome': 'Teste de dispositivo',
        'email': email,
        'senha': senha,
        'telefone': '11987654321',
        'tipo_usuario': 'Cidadão',
        'documento': '12345678900',
      },
    );
    final repo = ApiRepository();
    await repo.entrar(email, senha);
    final dados = <String, dynamic>{
      'especie': 'Cão',
      'porte': 'Grande',
      'estado_saude': 'Saudável',
      'status_ocorrencia': 'Perdido',
      'descricao_fisica': 'Animal em fotografia de teste.',
      'localizacao': {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'cidade': 'Jundiaí',
      },
      'numero_whatsapp': '11987654321',
    };
    final perdido = await repo.salvarOcorrencia(dados, [
      FotografiaEnvio('animal.jpg', compressed),
    ]);
    final emailB = 'notificacao-outro-$tag@example.test';
    await http.post(
      '/usuarios/cadastro',
      data: {
        'nome': 'Outro usuário de teste',
        'email': emailB,
        'senha': senha,
        'telefone': '11998765432',
        'tipo_usuario': 'ONG',
      },
    );
    final login = (await http.post(
      '/auth/login',
      data: {'email': emailB, 'senha': senha},
    )).data;
    final form = FormData.fromMap({
      'dados':
          '{"especie":"Cão","porte":"Grande","estado_saude":"Saudável","status_ocorrencia":"Encontrado","descricao_fisica":"Fotografia de teste.","localizacao":{"latitude":-23.18,"longitude":-46.89,"cidade":"Jundiaí"},"numero_whatsapp":"11998765432"}',
      'fotos': MultipartFile.fromBytes(compressed, filename: 'animal.jpg'),
    });
    final encontrado = (await http.post(
      '/ocorrencias',
      data: form,
      options: Options(headers: {'Authorization': 'Bearer ${login['token']}'}),
    )).data;
    final avisos = AvisosDispositivo(repo);
    try {
      await avisos.inicializar();
      final android = avisos.plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!;
      debugPrint('MIAR_NOTIF_NEGAR');
      for (
        var i = 0;
        i < 60 && await android.areNotificationsEnabled() != false;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      expect(await android.areNotificationsEnabled(), isFalse);
      await avisos.consultar();
      expect(
        (await repo.correspondencias()).first.dados['status_notificacao'],
        'Pendente',
      );
      expect(await avisos.plugin.getActiveNotifications(), isEmpty);
      debugPrint('MIAR_NOTIF_PERMITIR');
      for (
        var i = 0;
        i < 60 && await android.areNotificationsEnabled() != true;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      expect(await android.areNotificationsEnabled(), isTrue);
      await avisos.iniciarSessao();
      debugPrint('MIAR_NOTIF_AGENDAMENTO');
      await Future<void>.delayed(const Duration(seconds: 3));
      await avisos.consultar();
      final matches = await repo.correspondencias();
      expect(matches, isNotEmpty);
      expect(matches.first.dados['status_notificacao'], 'Emitida');
      final native = await avisos.plugin.getActiveNotifications();
      expect(native.any((n) => n.id == matches.first.id), isTrue);
    } finally {
      await avisos.plugin.cancelAll();
      avisos.dispose();
      await repo.excluir(perdido.id);
      await http.delete(
        '/ocorrencias/${encontrado['id_ocorrencia']}',
        options: Options(
          headers: {'Authorization': 'Bearer ${login['token']}'},
        ),
      );
      await repo.sair();
      await http.post(
        '/auth/logout',
        options: Options(
          headers: {'Authorization': 'Bearer ${login['token']}'},
        ),
      );
    }
  });
}
