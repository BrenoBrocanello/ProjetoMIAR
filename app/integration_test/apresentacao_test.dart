import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:miar/data/api_repository.dart';
import 'package:miar/data/notificacoes.dart';
import 'package:miar/domain/entidades.dart';
import 'package:miar/main.dart';
import 'package:miar/presentation/design.dart';
import 'package:miar/presentation/viewmodels.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Ensaio completo: cadastro, foto nativa, GPS, filtros, edição, seis status, radar, IA e exclusão pela interface',
    (tester) async {
      if (!apiUrl.endsWith(':3301')) {
        throw StateError('Use somente a API de teste.');
      }
      final tag = DateTime.now().millisecondsSinceEpoch.toString();
      debugPrint('MIAR_AUDIT_TAG=$tag');
      final repo = ApiRepository();
      await repo.storage.delete(key: 'sessao');
      final sessao = SessaoViewModel(repo);
      repo.sessaoExpirada = sessao.expirar;
      final avisos = AvisosDispositivo(repo);
      await sessao.iniciar();
      await tester.pumpWidget(MiarApp(sessao: sessao, avisos: avisos));
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      const senha = 'Apresentacao!42';
      final accounts = <Json>[];

      Finder campo(String label) => find.descendant(
        of: find.byElementPredicate(
          (e) =>
              e.widget is Campo &&
              (e.widget as Campo).label == label &&
              ModalRoute.of(e)?.isCurrent == true,
        ),
        matching: find.byType(TextFormField),
      );
      Future<void> tick() async {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
        await tester.pump(const Duration(milliseconds: 250));
      }

      Future<void> esperar(
        bool Function() ready, {
        String motivo = 'operação',
        int tentativas = 160,
      }) async {
        for (var i = 0; i < tentativas; i++) {
          await tick();
          var concluido = false;
          try {
            concluido = ready();
          } on StateError {
            // Finders .first/.last aguardam a montagem da rota de destino.
          }
          if (concluido) {
            await tester.pump(const Duration(milliseconds: 600));
            return;
          }
        }
        throw StateError('Não concluiu: $motivo');
      }

      Future<void> tocar(Finder f) async {
        final descricao = f.describeMatch(Plurality.one);
        await esperar(
          () => f.evaluate().length == 1,
          motivo: 'encontrar $descricao',
        );
        debugPrint('MIAR_AUDIT_UI=$descricao');
        await tester.ensureVisible(f);
        await tester.pump(const Duration(milliseconds: 300));
        await esperar(
          () => f.hitTestable().evaluate().length == 1,
          motivo: 'interação $descricao',
        );
        await tester.tap(f);
        await tester.pump(const Duration(milliseconds: 300));
      }

      Future<void> preencher(String label, String valor) async {
        await esperar(
          () => campo(label).evaluate().length == 1,
          motivo: 'campo $label',
        );
        await tester.ensureVisible(campo(label));
        await tester.enterText(campo(label), valor);
        await tester.pump();
      }

      Future<void> teclado() async {
        FocusManager.instance.primaryFocus?.unfocus();
        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        await tester.pump(const Duration(milliseconds: 300));
      }

      Future<T> api<T>(Future<T> Function() action) async =>
          (await tester.runAsync(action)) as T;

      Future<void> captura(String name) async {
        await teclado();
        if (find.byType(Foto).evaluate().isNotEmpty) {
          final imagens = find.descendant(
            of: find.byType(Foto),
            matching: find.byType(RawImage),
          );
          await esperar(
            () =>
                tester.widgetList<RawImage>(imagens).isNotEmpty &&
                tester
                    .widgetList<RawImage>(imagens)
                    .every((im) => im.image != null),
            motivo: 'fotografias visíveis para captura',
          );
        }
        await binding.takeScreenshot(name);
      }

      Future<void> entrar(Json conta) async {
        await preencher('E-mail', conta['email'] as String);
        await preencher('Senha', senha);
        await teclado();
        await tocar(find.widgetWithText(Botao, 'Entrar'));
        await esperar(
          () => find.text('Ocorrências').evaluate().isNotEmpty,
          motivo: 'login',
        );
      }

      Future<void> sair() async {
        await tocar(find.text('Perfil'));
        await tocar(find.widgetWithText(Botao, 'Sair da conta'));
        await esperar(
          () => find.text('Bem-vindo de volta').evaluate().isNotEmpty,
          motivo: 'logout',
        );
      }

      Future<void> cadastrar(String perfil, int n) async {
        final conta = <String, dynamic>{
          'nome': 'Apresentação $n',
          'email': 'apresentacao-$tag-$n@example.test',
          'perfil': perfil,
        };
        accounts.add(conta);
        await tocar(find.widgetWithText(Botao, 'Criar conta'));
        await tocar(
          find.text(perfil == 'Protetor independente' ? 'Protetor' : perfil),
        );
        for (final item in {
          'Nome completo': conta['nome'] as String,
          'E-mail': conta['email'] as String,
          'Telefone (com DDD)': '11987654321',
          'Documento (CPF/CNPJ)': 'Documento de auditoria',
          'Senha': senha,
        }.entries) {
          await preencher(item.key, item.value);
        }
        await teclado();
        await tocar(find.widgetWithText(Botao, 'Criar conta'));
        await esperar(
          () => find.text('Bem-vindo de volta').evaluate().isNotEmpty,
          motivo: 'cadastro $perfil',
        );
        await entrar(conta);
        expect(sessao.usuario!.perfil, perfil);
        expect(
          find.text('Radar'),
          perfil == 'Cidadão' ? findsNothing : findsOneWidget,
        );
        debugPrint('MIAR_AUDIT_ETAPA=CADASTRO_$n');
      }

      Future<void> dropdown(String label, String value) async {
        final f = find
            .byWidgetPredicate((w) => w is DropdownButtonFormField<String>)
            .at(label == 'Porte' ? 0 : 1);
        await tocar(f);
        await tocar(find.text(value).last);
      }

      Future<void> nova(
        String status,
        String description, {
        bool camera = false,
      }) async {
        await tocar(find.text('Registrar'));
        await tocar(find.text('Adicionar'));
        debugPrint(camera ? 'MIAR_AUDIT_CAMERA' : 'MIAR_AUDIT_GALERIA');
        await tocar(
          find.text(camera ? 'Tirar fotografia' : 'Escolher da galeria'),
        );
        await esperar(
          () => find.byTooltip('Remover fotografia').evaluate().isNotEmpty,
          motivo: 'retorno do seletor nativo',
          tentativas: 240,
        );
        await preencher('Espécie', 'Cão');
        await dropdown('Porte', 'Grande');
        await dropdown('Status da ocorrência', status);
        await preencher('Descrição física', description);
        await preencher(
          'Estado aparente de saúde',
          'Saudável, sem sinais aparentes de ferimentos.',
        );
        await preencher('Cidade', 'Jundiaí');
        await preencher('Estado (UF)', 'SP');
        await preencher('Endereço', 'Local de auditoria');
        await teclado();
        debugPrint('MIAR_AUDIT_GPS_PERMITIR');
        await tocar(find.text('Obter localização por GPS'));
        await esperar(
          () =>
              find.text('Atualizar localização por GPS').evaluate().isNotEmpty,
          motivo: 'GPS nativo',
        );
        await captura(
          'ensaio-formulario-${camera ? 'camera' : status.toLowerCase()}',
        );
        await tocar(find.widgetWithText(Botao, 'Cadastrar ocorrência'));
        await esperar(
          () =>
              find.text('Ocorrência').evaluate().isNotEmpty &&
              find.text(description).evaluate().isNotEmpty,
          motivo: 'gravação pela tela',
        );
        final own = await api(() => repo.ocorrencias(minhas: true));
        final o = own.items.firstWhere((o) => o.descricao == description);
        expect(o.fotos.length, greaterThan(0));
        expect(o.latitude, closeTo(-23.1857, .02));
        expect(o.longitude, closeTo(-46.8978, .02));
        expect(sessao.minhasTotal, greaterThan(0));
        await captura(
          'ensaio-detalhe-${camera ? 'camera' : status.toLowerCase()}',
        );
        debugPrint('MIAR_AUDIT_ETAPA=OCORRENCIA_${o.id}');
      }

      Future<void> inicio() async {
        if (find.byTooltip('Voltar').evaluate().isNotEmpty) {
          await tocar(find.byTooltip('Voltar'));
        }
        await esperar(
          () => find.text('Galeria').evaluate().isNotEmpty,
          motivo: 'navegação inferior',
        );
      }

      Future<void> status(String value) async {
        await tocar(find.text('Gerenciar'));
        await tocar(find.byTooltip('Gerenciar ocorrência').first);
        await tocar(find.text('Atualizar status'));
        await tocar(find.widgetWithText(ChoiceChip, value));
        await tocar(find.widgetWithText(Botao, 'Salvar alteração'));
        await esperar(
          () => find.text('Salvar alteração').evaluate().isEmpty,
          motivo: 'salvar status',
        );
        final own = await api(() => repo.ocorrencias(minhas: true));
        expect(own.items.first.status, value);
      }

      Future<void> excluir() async {
        await tocar(find.text('Gerenciar'));
        await tocar(find.byTooltip('Gerenciar ocorrência').first);
        await tocar(find.text('Excluir ocorrência'));
        await tocar(find.widgetWithText(TextButton, 'Excluir'));
        await esperar(
          () => sessao.minhasTotal == 0,
          motivo: 'excluir ocorrência',
        );
        expect((await api(() => repo.ocorrencias(minhas: true))).total, 0);
        debugPrint('MIAR_AUDIT_ETAPA=EXCLUSAO');
      }

      try {
        await captura('ensaio-login');
        await cadastrar('Cidadão', 0);
        expect(find.text('Gerenciar'), findsNothing);
        await tocar(find.text('Perfil'));
        await tocar(find.widgetWithText(Botao, 'Atualizar meus dados'));
        await preencher('Nome completo', 'Cidadão atualizado na interface');
        await teclado();
        await tocar(find.widgetWithText(Botao, 'Salvar meus dados'));
        await esperar(
          () => find.text('Salvar meus dados').evaluate().isEmpty,
          motivo: 'atualização do perfil',
        );
        expect(sessao.usuario!.nome, 'Cidadão atualizado na interface');
        await captura('ensaio-perfil-atualizado');
        await tocar(find.text('Galeria'));
        await nova('Perdido', 'Animal perdido cadastrado pela interface $tag');
        final perdido = (await api(
          () => repo.ocorrencias(minhas: true),
        )).items.first;
        await tocar(find.widgetWithText(Botao, 'Alterar minha ocorrência'));
        await esperar(
          () => campo('Descrição física').evaluate().isNotEmpty,
          motivo: 'carregar edição',
        );
        await preencher(
          'Descrição física',
          'Descrição alterada pela interface $tag',
        );
        await teclado();
        await tocar(find.widgetWithText(Botao, 'Salvar alterações'));
        await esperar(
          () => find
              .text('Descrição alterada pela interface $tag')
              .evaluate()
              .isNotEmpty,
          motivo: 'editar ocorrência',
        );
        expect(
          (await api(() => repo.ocorrencia(perdido.id))).fotos.first['id_foto'],
          perdido.fotos.first['id_foto'],
        );
        await inicio();
        await tocar(find.text('Galeria'));
        await tocar(find.byTooltip('Filtrar ocorrências'));
        await preencher('Espécie', 'Cão');
        await preencher('Porte', 'Grande');
        await preencher('Cidade', 'Cidade inexistente $tag');
        await teclado();
        await tocar(find.widgetWithText(Botao, 'Aplicar filtros'));
        await esperar(
          () =>
              find
                  .text('Nenhuma ocorrência encontrada para estes filtros.')
                  .evaluate()
                  .isNotEmpty ||
              find
                  .text('Nenhuma ocorrência corresponde aos filtros.')
                  .evaluate()
                  .isNotEmpty,
          motivo: 'resultado vazio',
        );
        await tocar(find.byTooltip('Filtrar ocorrências'));
        await tocar(find.text('Limpar filtros'));
        await esperar(
          () => find.text('Cão · Grande').evaluate().isNotEmpty,
          motivo: 'limpar filtros',
        );
        for (final value in [
          'Encontrado',
          'Emergência',
          'Aguardando Adoção',
          'Adotado',
          'Resgatado',
          'Perdido',
        ]) {
          await status(value);
          if (['Adotado', 'Resgatado'].contains(value)) {
            await tocar(find.text('Cão · Grande').first);
            await esperar(
              () => find
                  .text(
                    'Ocorrência encerrada. O contato público está desabilitado.',
                  )
                  .evaluate()
                  .isNotEmpty,
              motivo: 'contato encerrado',
            );
            expect(
              find.widgetWithText(Botao, 'Falar no WhatsApp'),
              findsNothing,
            );
            await tester.ensureVisible(
              find.text(
                'Ocorrência encerrada. O contato público está desabilitado.',
              ),
            );
            await captura('ensaio-contato-oculto-${value.toLowerCase()}');
            await inicio();
          }
        }
        await sair();
        await cadastrar('Protetor independente', 1);
        await nova(
          'Encontrado',
          'Animal encontrado cadastrado pela interface $tag',
        );
        await inicio();
        await tocar(find.text('Radar'));
        final tiles = find.descendant(
          of: find.byType(FlutterMap),
          matching: find.byType(RawImage),
        );
        await esperar(
          () =>
              tester.widgetList<RawImage>(tiles).isNotEmpty &&
              tester
                  .widgetList<RawImage>(tiles)
                  .every(
                    (im) => im.image != null && (im.opacity?.value ?? 1) >= 1,
                  ),
          motivo: 'mapa completo',
        );
        final marcador = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label ?? '').startsWith('Cão, Perdido,'),
        );
        await tocar(marcador.first);
        await captura('ensaio-radar-com-resumo');
        await tocar(find.text('Galeria'));
        await sair();
        await entrar(accounts[0]);
        await esperar(
          () => find
              .text('Possível correspondência encontrada')
              .evaluate()
              .isNotEmpty,
          motivo: 'aviso de correspondência',
        );
        await tocar(find.text('Possível correspondência encontrada').first);
        await esperar(
          () => find.text('PERCENTUAL DE CONFIANÇA').evaluate().isNotEmpty,
          motivo: 'abrir comparação',
        );
        await captura('ensaio-correspondencia-real');
        expect(
          (await api(() => repo.correspondencias())).first.confianca,
          greaterThan(99),
        );
        await inicio();
        await excluir();
        await sair();
        await entrar(accounts[1]);
        await excluir();
        await sair();
        await cadastrar('ONG', 2);
        await nova(
          'Encontrado',
          'Fotografia obtida pela câmera virtual $tag',
          camera: true,
        );
        await inicio();
        await excluir();
        await sair();
        expect(find.text('Bem-vindo de volta'), findsOneWidget);
        expect(tester.takeException(), isNull);
        debugPrint('MIAR_AUDIT_ETAPA=ENSAIO_COMPLETO_APROVADO');
      } finally {
        // Compensação somente das contas desta execução, se o teste interromper um fluxo.
        final http = Dio(BaseOptions(baseUrl: apiUrl));
        for (final conta in accounts) {
          try {
            final auth = (await http.post(
              '/auth/login',
              data: {'email': conta['email'], 'senha': senha},
            )).data;
            final options = Options(
              headers: {'Authorization': 'Bearer ${auth['token']}'},
            );
            final own = (await http.get(
              '/ocorrencias/minhas',
              options: options,
            )).data;
            for (final o in own['items']) {
              await http.delete(
                '/ocorrencias/${o['id_ocorrencia']}',
                options: options,
              );
            }
            await http.post('/auth/logout', options: options);
          } catch (_) {}
        }
        avisos.dispose();
        await tester.pumpWidget(const SizedBox());
        sessao.dispose();
        http.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
