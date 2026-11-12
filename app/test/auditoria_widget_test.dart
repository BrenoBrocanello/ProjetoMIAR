import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:miar/domain/entidades.dart';
import 'package:miar/presentation/design.dart';
import 'package:miar/presentation/galeria_page.dart';
import 'fluxos_widget_test.dart' as base;

Finder field(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is Campo && w.label == label),
  matching: find.byType(TextFormField),
);

class RepositorioAuditoria extends base.RepositorioTeste {
  bool falhar = false;
  final registro = Ocorrencia({
    'id_ocorrencia': 1,
    'id_usuario_responsavel': 1,
    'especie': 'Cão',
    'porte': 'Grande',
    'status_ocorrencia': 'Perdido',
    'descricao_fisica':
        'Descrição longa para conferir a leitura do animal na interface.',
    'estado_saude': 'Sem ferimentos aparentes',
    'data_registro': '2026-11-11',
    'localizacao': {
      'latitude': -23.18,
      'longitude': -46.89,
      'cidade': 'Jundiaí',
      'endereco': 'Endereço de auditoria',
    },
    'responsavel': {'nome': 'Pessoa responsável'},
    'fotos': [
      {'id_foto': 1, 'url_storage': 'https://example.invalid/foto.jpg'},
    ],
    'contato': {'numero_whatsapp': '11987654321'},
  });
  @override
  Future<PaginaOcorrencias> ocorrencias({
    Json filtros = const {},
    bool minhas = false,
    bool radar = false,
    int pagina = 0,
  }) async {
    if (falhar) throw Exception('Consulta indisponível na auditoria.');
    return PaginaOcorrencias([registro], 1);
  }

  @override
  Future<Ocorrencia> ocorrencia(int id, {bool editar = false}) async =>
      registro;
  @override
  Future<Correspondencia> correspondencia(int id) async => Correspondencia({
    'id_correspondencia': id,
    'status_notificacao': 'Pendente',
    'percentual_confianca': 87.0,
    'data_analise': '2026-11-11T12:00:00Z',
    'origem': registro.dados,
    'perdido': registro.dados,
  });
}

void main() {
  testWidgets('RNF06: campos têm nome acessível para leitor de tela', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await base.montar(tester, base.RepositorioTeste());
    for (final label in ['E-mail', 'Senha']) {
      final node = tester.getSemantics(field(label));
      expect(node.getSemanticsData().label, contains(label));
    }
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });
  for (final perfil in perfis) {
    testWidgets(
      'CU01: envia cadastro $perfil pela interface, sem campos extras',
      (tester) async {
        final repo = base.RepositorioTeste();
        await base.montar(tester, repo);
        await tester.ensureVisible(find.text('Criar conta'));
        await tester.tap(find.text('Criar conta'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(perfil == 'Protetor independente' ? 'Protetor' : perfil),
        );
        await tester.pumpAndSettle();
        for (final e in {
          'Nome completo': 'Pessoa de teste',
          'E-mail': 'auditoria@example.test',
          'Telefone (com DDD)': '11987654321',
          'Documento (CPF/CNPJ)': 'Teste',
          'Senha': 'Senha!42',
        }.entries) {
          await tester.ensureVisible(field(e.key));
          await tester.enterText(field(e.key), e.value);
        }
        await tester.ensureVisible(find.widgetWithText(Botao, 'Criar conta'));
        await tester.tap(find.widgetWithText(Botao, 'Criar conta'));
        await tester.pumpAndSettle();
        expect(repo.cadastro?.keys.toSet(), {
          'nome',
          'email',
          'telefone',
          'documento',
          'senha',
          'tipo_usuario',
        });
        expect(repo.cadastro?['tipo_usuario'], perfil);
        expect(find.text('Bem-vindo de volta'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  for (final size in [
    const Size(320, 568),
    const Size(393, 852),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    for (final scale in [1.0, 1.8]) {
      testWidgets(
        'RNF01/RNF06: nove janelas em ${size.width}x${size.height}, fonte $scale',
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final repo = RepositorioAuditoria()..atual = base.usuario('ONG');
          await base.montar(tester, repo, tamanho: size);
          final router = GoRouter.of(tester.element(find.byType(GaleriaPage)));
          for (final route in [
            '/radar',
            '/registrar',
            '/ocorrencia/1',
            '/registrar/1',
            '/gerenciar',
            '/correspondencia/1',
            '/perfil',
          ]) {
            router.go(route);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: route);
          }
          await tester.ensureVisible(find.text('Atualizar meus dados'));
          await tester.tap(find.text('Atualizar meus dados'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'edição de perfil');
          await tester.pumpWidget(const SizedBox());
          await base.montar(tester, base.RepositorioTeste(), tamanho: size);
          await tester.ensureVisible(find.text('Criar conta'));
          await tester.tap(find.text('Criar conta'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'cadastro');
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  testWidgets(
    'CU03/RNF03: falha da galeria é informada e nova tentativa recupera dados',
    (tester) async {
      final repo = RepositorioAuditoria()
        ..atual = base.usuario('Cidadão')
        ..falhar = true;
      await base.montar(tester, repo);
      expect(find.textContaining('Consulta indisponível'), findsOneWidget);
      repo.falhar = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Cão · Grande'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
