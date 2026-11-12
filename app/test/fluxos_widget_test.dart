import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miar/main.dart';
import 'package:miar/domain/entidades.dart';
import 'package:miar/domain/miar_repository.dart';
import 'package:miar/presentation/viewmodels.dart';
import 'package:miar/presentation/design.dart';

class RepositorioTeste implements MiarRepository {
  @override
  Stream<void> mudancas() => const Stream.empty();
  Usuario? atual;
  int total = 0;
  bool falharLogin = false;
  Json? cadastro;
  @override
  Future<Usuario?> restaurarSessao() async => atual;
  @override
  Future<Usuario> entrar(String email, String senha) async {
    if (falharLogin) throw Exception('Serviço indisponível.');
    return atual = usuario('Cidadão');
  }

  @override
  Future<void> sair() async {
    atual = null;
  }

  @override
  Future<Usuario> cadastrar(Json dados) async {
    cadastro = dados;
    return usuario(dados['tipo_usuario'] as String);
  }

  @override
  Future<PaginaOcorrencias> ocorrencias({
    Json filtros = const {},
    bool minhas = false,
    bool radar = false,
    int pagina = 0,
  }) async => PaginaOcorrencias([], minhas ? total : 0);
  @override
  Future<List<Correspondencia>> correspondencias() async => [];
  @override
  String fotoUrl(String caminho) => caminho;
  @override
  Future<Usuario> atualizarPerfil(Json dados) async =>
      atual = Usuario({...atual!.dados, ...dados});
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Usuario usuario(String perfil) => Usuario({
  'id_usuario': 1,
  'nome': 'Usuário de teste',
  'email': 'teste@example.test',
  'telefone': '11987654321',
  'tipo_usuario': perfil,
  'ativo': true,
  'documento': '12345678900',
});
Future<SessaoViewModel> montar(
  WidgetTester tester,
  RepositorioTeste repo, {
  double escala = 1,
  Size tamanho = const Size(402, 852),
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final sessao = SessaoViewModel(repo);
  await sessao.iniciar();
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(escala)),
      child: MiarApp(sessao: sessao),
    ),
  );
  await tester.pumpAndSettle();
  return sessao;
}

void main() {
  testWidgets(
    'Login valida campos e não confirma acesso quando o serviço falha',
    (tester) async {
      final repo = RepositorioTeste()..falharLogin = true;
      await montar(tester, repo);
      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('Informe e-mail.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'teste@example.test',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'senha');
      await tester.ensureVisible(find.text('Entrar'));
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Serviço indisponível'), findsOneWidget);
      expect(find.text('Bem-vindo de volta'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Cadastro centraliza documento em USUARIO nos três perfis do RD01',
    (tester) async {
      final repo = RepositorioTeste();
      await montar(tester, repo);
      await tester.ensureVisible(find.text('Criar conta'));
      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();
      expect(find.text('Documento (CPF/CNPJ)'), findsOneWidget);
      await tester.tap(find.text('ONG'));
      await tester.pumpAndSettle();
      expect(find.text('Documento (CPF/CNPJ)'), findsOneWidget);
      expect(find.text('Nome fantasia'), findsNothing);
      await tester.tap(find.text('Protetor'));
      await tester.pumpAndSettle();
      expect(find.text('Documento (CPF/CNPJ)'), findsOneWidget);
      expect(find.text('Nome da instituição'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final perfil in perfis) {
    testWidgets(
      '$perfil gerencia seus próprios registros; radar respeita CU09',
      (tester) async {
        final repo = RepositorioTeste()
          ..atual = usuario(perfil)
          ..total = 1;
        await montar(tester, repo);
        expect(find.text('Gerenciar'), findsOneWidget);
        expect(
          find.text('Radar'),
          perfil == 'Cidadão' ? findsNothing : findsOneWidget,
        );
        await tester.tap(find.text('Perfil'));
        await tester.pumpAndSettle();
        expect(find.text('Usuário de teste'), findsOneWidget);
        expect(find.text('Sair da conta'), findsOneWidget);
        await tester.ensureVisible(find.text('Sair da conta'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sair da conta'));
        await tester.pumpAndSettle();
        expect(find.text('Bem-vindo de volta'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('Gerenciar não aparece antes de existir registro próprio', (
    tester,
  ) async {
    await montar(tester, RepositorioTeste()..atual = usuario('Cidadão'));
    expect(find.text('Gerenciar'), findsNothing);
    expect(find.text('Nenhuma ocorrência cadastrada.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Filtros abrem com os quatro critérios documentados', (
    tester,
  ) async {
    await montar(
      tester,
      RepositorioTeste()..atual = usuario('Protetor independente'),
    );
    await tester.tap(find.byTooltip('Filtrar ocorrências'));
    await tester.pumpAndSettle();
    for (final label in ['Status', 'Espécie', 'Porte', 'Cidade']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Login permanece utilizável em tela pequena com teclado', (
    tester,
  ) async {
    await montar(tester, RepositorioTeste(), tamanho: const Size(320, 568));
    await tester.ensureVisible(find.byType(TextFormField).first);
    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();
    await tester.ensureVisible(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Criar conta'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Escala tipográfica ampliada mantém botões e navegação acessíveis',
    (tester) async {
      final repo = RepositorioTeste()..atual = usuario('ONG');
      final s = SessaoViewModel(repo);
      await s.iniciar();
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(MiarApp(sessao: s));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sair da conta'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Status usa sempre identificação textual, além de cor', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: Miar.theme,
        home: Scaffold(
          body: Wrap(
            children: [for (final s in statusOcorrencia) BadgeStatus(s)],
          ),
        ),
      ),
    );
    for (final s in statusOcorrencia) {
      expect(find.text(s), findsOneWidget);
    }
  });
}
