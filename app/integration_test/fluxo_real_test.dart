import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:integration_test/integration_test.dart';
import 'package:miar/data/api_repository.dart';
import 'package:miar/domain/entidades.dart';
import 'package:miar/main.dart';
import 'package:miar/presentation/viewmodels.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('As nove janelas usam a API real no Android', (tester) async {
    if (!apiUrl.endsWith(':3301')) {
      throw StateError('Execute somente contra a API isolada na porta 3301.');
    }
    final tag = DateTime.now().millisecondsSinceEpoch;
    final email = 'visual-$tag@example.test', senha = 'Teste visual!42';
    final http = Dio(BaseOptions(baseUrl: apiUrl));
    await http.post(
      '/usuarios/cadastro',
      data: {
        'nome': 'Protetora de teste',
        'email': email,
        'senha': senha,
        'telefone': '11987654321',
        'tipo_usuario': 'Protetor independente',
        'documento': 'Teste',
      },
    );
    final otherEmail = 'visual-outro-$tag@example.test';
    await http.post(
      '/usuarios/cadastro',
      data: {
        'nome': 'Cidadão de teste',
        'email': otherEmail,
        'senha': senha,
        'telefone': '11998765432',
        'tipo_usuario': 'Cidadão',
        'documento': '12345678900',
      },
    );
    final repo = ApiRepository();
    await repo.storage.delete(key: 'sessao');
    final sessao = SessaoViewModel(repo);
    repo.sessaoExpirada = sessao.expirar;
    await sessao.iniciar();
    await tester.pumpWidget(MiarApp(sessao: sessao));
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('01-login');
    await tester.ensureVisible(find.text('Criar conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02-criar-cadastro');
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), senha);
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Entrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Ocorrências'), findsOneWidget);
    final login = (await http.post(
      '/auth/login',
      data: {'email': otherEmail, 'senha': senha},
    )).data;
    final animal = await rootBundle.load('assets/img/hero-cao-gato.jpg');
    final dados = <String, dynamic>{
      'especie': 'Cão',
      'porte': 'Grande',
      'estado_saude': 'Saudável, sem sinais de ferimentos.',
      'status_ocorrencia': 'Perdido',
      'descricao_fisica': 'Pelagem caramelo e coleira azul. Registro de teste.',
      'localizacao': {
        'latitude': -23.1857,
        'longitude': -46.8978,
        'cidade': 'Jundiaí',
        'endereco': 'Localização de teste',
      },
      'numero_whatsapp': '11987654321',
    };
    final perdido = await repo.salvarOcorrencia(dados, [
      FotografiaEnvio('animal.jpg', animal.buffer.asUint8List()),
    ]);
    final form = FormData.fromMap({
      'dados':
          '{"especie":"Cão","porte":"Grande","estado_saude":"Saudável","status_ocorrencia":"Encontrado","descricao_fisica":"Pelagem caramelo, ocorrência de teste.","localizacao":{"latitude":-23.181,"longitude":-46.894,"cidade":"Jundiaí"},"numero_whatsapp":"11998765432"}',
      'fotos': MultipartFile.fromBytes(
        animal.buffer.asUint8List(),
        filename: 'animal.jpg',
      ),
    });
    final encontrado = (await http.post(
      '/ocorrencias',
      data: form,
      options: Options(headers: {'Authorization': 'Bearer ${login['token']}'}),
    )).data;
    await sessao.atualizarContexto();
    // Reentra na galeria para consultar os registros recém-criados.
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galeria'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('03-galeria');
    final card = find.text('Cão · Grande').first;
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('05-detalhe');
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Radar'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    // Descargas/decodificações de tiles não mantêm pumpAndSettle ocupado.
    // Aguarda cada imagem visível; uma captura parcial não valida o radar.
    final tiles = find.descendant(
      of: find.byType(FlutterMap),
      matching: find.byType(RawImage),
    );
    var mapaCompleto = false;
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump(const Duration(milliseconds: 250));
      final imagens = tester.widgetList<RawImage>(tiles).toList();
      mapaCompleto =
          imagens.isNotEmpty &&
          imagens.every(
            (im) => im.image != null && (im.opacity?.value ?? 1) >= 1,
          );
      if (mapaCompleto) break;
    }
    expect(
      mapaCompleto,
      isTrue,
      reason: 'Todos os tiles visíveis do radar devem estar carregados.',
    );
    await tester.pumpAndSettle();
    await binding.takeScreenshot('04-radar');
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('06-cadastrar');
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gerenciar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Gerenciar ocorrência').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atualizar status'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('07-gerenciar');
    await tester.tapAt(const Offset(20, 100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galeria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Possível correspondência encontrada').first);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('08-correspondencia');
    expect(find.text('PERCENTUAL DE CONFIANÇA'), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('09-perfil');
    expect(find.text('Protetora de teste'), findsOneWidget);
    // Limpa somente as ocorrências produzidas por este teste.
    await repo.excluir(perdido.id);
    await http.delete(
      '/ocorrencias/${encontrado['id_ocorrencia']}',
      options: Options(headers: {'Authorization': 'Bearer ${login['token']}'}),
    );
    await repo.sair();
    sessao.dispose();
    await http.post(
      '/auth/logout',
      options: Options(headers: {'Authorization': 'Bearer ${login['token']}'}),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
