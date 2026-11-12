import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:miar/data/api_repository.dart';
import 'package:miar/domain/entidades.dart';
import 'package:miar/main.dart';
import 'package:miar/presentation/auth_pages.dart';
import 'package:miar/presentation/design.dart';
import 'package:miar/presentation/viewmodels.dart';

// Somente os cenários vazios/indisponíveis são induzidos neste cliente de teste.
// Dados, fotos, credenciais e demais consultas usam a API/PG/S3/IA reais em 3301.
class RepositorioCatalogo extends ApiRepository {
  bool vazio = false, falha = false, falhaMapa = false;
  @override
  Future<PaginaOcorrencias> ocorrencias({
    Json filtros = const {},
    bool minhas = false,
    bool radar = false,
    int pagina = 0,
  }) {
    if (falha) {
      throw Falha(
        'Não foi possível conectar ao MIAR. Verifique sua conexão e tente novamente.',
      );
    }
    if (vazio) return Future.value(PaginaOcorrencias([], 0));
    return super.ocorrencias(
      filtros: filtros,
      minhas: minhas,
      radar: radar,
      pagina: pagina,
    );
  }

  @override
  String fotoUrl(String caminho) => falhaMapa && caminho.startsWith('/mapa/')
      ? 'http://127.0.0.1:9$caminho'
      : super.fotoUrl(caminho);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Catálogo integral de telas, formulários, modais e estados visuais',
    (tester) async {
      if (!apiUrl.endsWith(':3301')) {
        throw StateError('Catálogo exige a API isolada.');
      }
      final tag = DateTime.now().millisecondsSinceEpoch;
      final repo = RepositorioCatalogo();
      final sessao = SessaoViewModel(repo);
      repo.sessaoExpirada = sessao.expirar;
      await repo.storage.delete(key: 'sessao');
      final http = Dio(BaseOptions(baseUrl: apiUrl));
      final contas = <Json>[];
      final registros = <Json>[];
      const senha = 'Catalogo visual!42';
      var seq = 0;
      Future<T> real<T>(Future<T> Function() fn) async =>
          (await tester.runAsync(fn)) as T;
      Future<void> tick() async {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 200));
      }

      Future<void> esperar(bool Function() ready, String motivo) async {
        for (var i = 0; i < 180; i++) {
          await tick();
          try {
            if (ready()) return;
          } on StateError {
            /* rota ainda em montagem */
          }
        }
        throw StateError('Catálogo não concluiu $motivo.');
      }

      Future<void> tocar(Finder f) async {
        await esperar(
          () => f.evaluate().length == 1,
          f.describeMatch(Plurality.one),
        );
        await tester.ensureVisible(f);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(f);
        await tester.pump(const Duration(milliseconds: 600));
      }

      Future<void> foto(
        String nome,
        String titulo,
        String requisitos, {
        String fonte = 'API e serviços reais',
        bool imagens = false,
      }) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        await tester.pump(const Duration(milliseconds: 600));
        if (imagens) {
          final raw = find.descendant(
            of: find.byType(Foto),
            matching: find.byType(RawImage),
          );
          try {
            await esperar(
              () =>
                  tester.widgetList<RawImage>(raw).isNotEmpty &&
                  raw.evaluate().length ==
                      find.byType(Foto).evaluate().length &&
                  tester
                      .widgetList<RawImage>(raw)
                      .every((i) => i.image != null),
              'imagens em $nome',
            );
          } catch (_) {
            debugPrint(
              'MIAR_DIAGNOSTICO=${jsonEncode({'tela': nome, 'fotos': find.byType(Foto).evaluate().length, 'raw': raw.evaluate().length, 'textos': tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).whereType<String>().take(16).toList()})}',
            );
            await binding.takeScreenshot('diagnostico-$nome');
            rethrow;
          }
        }
        final id = '${(++seq).toString().padLeft(3, '0')}-$nome';
        final meta = {
          'nome': id,
          'titulo': titulo,
          'requisitos': requisitos,
          'fonte': fonte,
          'ordem': seq,
        };
        await binding.takeScreenshot(id);
        debugPrint('MIAR_CATALOGO_META=${jsonEncode(meta)}');
        debugPrint('MIAR_CATALOGO=$id');
      }

      late GoRouter router;
      Future<void> ir(String path) async {
        router.go(path);
        await tester.pump(const Duration(milliseconds: 800));
        await esperar(
          () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
          path,
        );
        await tester.pump(const Duration(milliseconds: 500));
      }

      Future<void> fundo(String texto) async {
        await esperar(
          () => find.text(texto).evaluate().isNotEmpty,
          'conteúdo: $texto',
        );
        await tester.ensureVisible(find.text(texto).last);
        await tester.pump(const Duration(milliseconds: 500));
      }

      Future<void> partesFormulario(String prefixo, String titulo) async {
        await foto(
          '$prefixo-superior',
          '$titulo — fotografias, espécie, porte e status',
          'RF02, RF08, RD02',
        );
        final campo = find.byWidgetPredicate(
          (w) => w is Campo && w.label == 'Descrição física',
        );
        await tester.ensureVisible(campo);
        await tester.pump(const Duration(milliseconds: 500));
        await foto(
          '$prefixo-meio',
          '$titulo — descrição física e saúde',
          'RF02',
        );
        await fundo('WhatsApp para contato');
        await foto(
          '$prefixo-inferior',
          '$titulo — cidade, UF, endereço, GPS e contato',
          'RF02, RD03, RD05',
        );
      }

      Future<void> usuario(int i) async {
        if (sessao.usuario != null) await real(sessao.sair);
        await real(() => sessao.entrar(contas[i]['email'] as String, senha));
        await ir('/galeria');
      }

      try {
        await tester.pumpWidget(MiarApp(sessao: sessao));
        await tester.pump(const Duration(milliseconds: 300));
        await binding.convertFlutterSurfaceToImage();
        await foto(
          'inicializacao',
          'Inicialização e restauração da sessão',
          'RF01',
          fonte: 'Tela técnica de carga; não é uma nova função',
        );
        await real(sessao.iniciar);
        await tester.pumpAndSettle();
        router = GoRouter.of(tester.element(find.byType(LoginPage)));
        await foto('login', 'Login', 'RF01, CU02');
        await tocar(find.widgetWithText(Botao, 'Entrar'));
        await foto(
          'login-validacao',
          'Login — campos obrigatórios',
          'RF01, CU02',
        );
        for (final perfil in perfis) {
          await ir('/cadastro');
          await tocar(
            find.text(perfil == 'Protetor independente' ? 'Protetor' : perfil),
          );
          final suffix = perfis.indexOf(perfil).toString();
          await foto(
            'cadastro-$suffix-superior',
            'Cadastro $perfil — seleção do perfil e dados pessoais',
            'RF01, RD01, CU01',
          );
          await fundo('Documento (CPF/CNPJ)');
          await foto(
            'cadastro-$suffix-inferior',
            'Cadastro $perfil — documento, senha e confirmação',
            'RF01, RD01, CU01',
          );
          if (perfil == perfis.last) {
            await tocar(find.widgetWithText(Botao, 'Criar conta'));
            await foto(
              'cadastro-validacao',
              'Cadastro — validação dos campos obrigatórios',
              'RF01, CU01',
            );
          }
        }
        await ir('/login');
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'nao-cadastrado-$tag@example.test',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'credencial incorreta',
        );
        await tocar(find.widgetWithText(Botao, 'Entrar'));
        await esperar(
          () => !tester
              .widget<Botao>(find.widgetWithText(Botao, 'Entrar'))
              .ocupado,
          'credencial inválida',
        );
        await foto(
          'login-credencial-invalida',
          'Login — credencial rejeitada pelo servidor',
          'RF01, CU02',
        );
        final animal = (await rootBundle.load(
          'assets/img/hero-cao-gato.jpg',
        )).buffer.asUint8List();
        for (var i = 0; i < perfis.length; i++) {
          final email = 'catalogo-$tag-$i@example.test';
          await real(
            () => http.post(
              '/usuarios/cadastro',
              data: {
                'nome': 'Catálogo ${perfis[i]}',
                'email': email,
                'senha': senha,
                'telefone': '11987654321',
                'tipo_usuario': perfis[i],
                'documento': 'Ensaio visual',
              },
            ),
          );
          final auth = (await real(
            () => http.post(
              '/auth/login',
              data: {'email': email, 'senha': senha},
            ),
          )).data;
          contas.add({'email': email, 'token': auth['token']});
        }
        await usuario(2);
        repo.vazio = true;
        await ir('/perfil');
        await ir('/galeria');
        await foto(
          'galeria-vazia',
          'Galeria — ausência de ocorrências',
          'RF03, CU03',
          fonte: 'Estado vazio induzido apenas no repositório deste cliente',
        );
        await ir('/gerenciar');
        await foto(
          'gerenciar-vazio',
          'Gerenciar — ausência de registros próprios',
          'RF02, CU08',
          fonte: 'Estado vazio induzido apenas no repositório deste cliente',
        );
        await ir('/radar');
        final tilesVazios = find.descendant(
          of: find.byType(FlutterMap),
          matching: find.byType(RawImage),
        );
        await esperar(
          () =>
              tester.widgetList<RawImage>(tilesVazios).isNotEmpty &&
              tester
                  .widgetList<RawImage>(tilesVazios)
                  .every(
                    (i) => i.image != null && (i.opacity?.value ?? 1) >= 1,
                  ),
          'mapa vazio completo',
        );
        await foto(
          'radar-vazio',
          'Radar — mapa sem ocorrências',
          'RF04, CU09',
          fonte: 'Mapa real; consulta vazia induzida neste cliente',
        );
        repo.vazio = false;
        for (var i = 0; i < statusOcorrencia.length; i++) {
          final owner = i % 3;
          final dados = {
            'especie': 'Cão',
            'porte': 'Grande',
            'estado_saude': 'Sem ferimentos aparentes.',
            'status_ocorrencia': statusOcorrencia[i],
            'descricao_fisica':
                'Registro ${statusOcorrencia[i]} do catálogo. Pelagem caramelo e coleira azul.',
            'localizacao': {
              'latitude': -23.1857 + i * .002,
              'longitude': -46.8978 + i * .002,
              'cidade': 'Jundiaí',
              'estado': 'SP',
              'endereco': 'Local de ensaio visual',
            },
            'numero_whatsapp': '11987654321',
          };
          final f = FormData.fromMap({
            'dados': const JsonEncoder().convert(dados),
            'fotos': MultipartFile.fromBytes(animal, filename: 'animal.jpg'),
          });
          final o = (await real(
            () => http.post(
              '/ocorrencias',
              data: f,
              options: Options(
                headers: {'Authorization': 'Bearer ${contas[owner]['token']}'},
              ),
            ),
          )).data;
          registros.add({
            'id': o['id_ocorrencia'],
            'owner': owner,
            'status': statusOcorrencia[i],
          });
        }
        await real(sessao.atualizarContexto);
        await ir('/perfil');
        await ir('/galeria');
        await foto(
          'galeria',
          'Galeria — registros e aviso de correspondência',
          'RF03, RF06, CU03',
          imagens: true,
        );
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pump(const Duration(milliseconds: 600));
        await foto(
          'galeria-rolagem',
          'Galeria — continuação dos seis status',
          'RF03, RD02, CU03',
          imagens: true,
        );
        await ir('/perfil');
        await ir('/galeria');
        await tocar(find.byTooltip('Filtrar ocorrências'));
        await foto(
          'filtros',
          'Filtros — status, espécie, porte e cidade',
          'RF03, CU04',
        );
        final cidadeFiltro = find.descendant(
          of: find.byWidgetPredicate((w) => w is Campo && w.label == 'Cidade'),
          matching: find.byType(TextFormField),
        );
        await tester.ensureVisible(cidadeFiltro);
        await tester.enterText(cidadeFiltro, 'Sem resultados $tag');
        await tocar(find.widgetWithText(Botao, 'Aplicar filtros'));
        await esperar(
          () => find
              .text('Nenhuma ocorrência corresponde aos filtros.')
              .evaluate()
              .isNotEmpty,
          'filtro sem resultados',
        );
        await foto(
          'galeria-sem-resultados',
          'Galeria — filtros ativos sem resultados',
          'RF03, CU04',
        );
        await tocar(find.byTooltip('Filtrar ocorrências'));
        await tocar(find.text('Limpar filtros'));
        await esperar(
          () => find.byType(BottomSheet).evaluate().isEmpty,
          'fechar filtros',
        );
        await ir('/radar');
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
                    (i) => i.image != null && (i.opacity?.value ?? 1) >= 1,
                  ),
          'mapa completo',
        );
        await foto('radar', 'Radar — mapa, marcadores e filtros', 'RF04, CU09');
        final marcador = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label ?? '').startsWith('Cão, Perdido,'),
        );
        await tocar(marcador.first);
        await foto(
          'radar-resumo',
          'Radar — marcador selecionado e resumo da ocorrência',
          'RF04, CU09',
          imagens: true,
        );
        repo.falhaMapa = true;
        await ir('/perfil');
        await ir('/radar');
        await esperar(
          () => find
              .text('Não foi possível carregar o mapa. Verifique sua conexão.')
              .evaluate()
              .isNotEmpty,
          'indisponibilidade de mapa',
        );
        await foto(
          'radar-falha',
          'Radar — mapa indisponível e nova tentativa',
          'RNF03, CU09',
          fonte:
              'Falha de rede induzida neste cliente; sem alteração do servidor',
        );
        repo.falhaMapa = false;
        await ir('/registrar');
        await partesFormulario('registro', 'Cadastro de ocorrência');
        await ir('/perfil');
        await ir('/registrar');
        await tocar(find.text('Adicionar'));
        await foto(
          'origem-fotografia',
          'Fotografia — escolher câmera ou galeria',
          'RF02, CU05',
        );
        await tester.tapAt(const Offset(15, 100));
        await tester.pump(const Duration(milliseconds: 700));
        for (final status in ['Encontrado', 'Adotado', 'Resgatado']) {
          final id = registros.firstWhere((r) => r['status'] == status)['id'];
          await ir('/galeria');
          await ir('/ocorrencia/$id');
          await esperar(
            () =>
                find.widgetWithText(BadgeStatus, status).evaluate().isNotEmpty,
            'status $status',
          );
          await foto(
            'detalhe-${status.toLowerCase()}',
            'Detalhe — status $status, fotografia e descrição',
            'RF02, RF08, RD06, CU03',
            imagens: true,
          );
          await fundo(
            status == 'Encontrado'
                ? 'Falar no WhatsApp'
                : 'Ocorrência encerrada. O contato público está desabilitado.',
          );
          await foto(
            'contato-${status.toLowerCase()}',
            'Detalhe — contato ${status == 'Encontrado' ? 'disponível' : 'público desabilitado'} ($status)',
            'RF07, RD06, CU10',
          );
        }
        await usuario(0);
        final perdido = registros.firstWhere(
          (r) => r['status'] == 'Perdido',
        )['id'];
        await ir('/registrar/$perdido');
        await partesFormulario('edicao', 'Edição de ocorrência própria');
        await ir('/gerenciar');
        await foto(
          'gerenciar',
          'Gerenciar — somente registros próprios',
          'RF02, RD04, CU08',
          imagens: true,
        );
        await tocar(find.byTooltip('Gerenciar ocorrência').first);
        await foto(
          'gerenciar-menu',
          'Gerenciar — menu de status, alteração e exclusão',
          'RF02, RF08, CU07, CU08',
        );
        await tocar(find.text('Atualizar status'));
        await foto(
          'gerenciar-status',
          'Gerenciar — seis status e confirmação',
          'RF08, RD02, CU07',
        );
        await tester.tapAt(const Offset(15, 100));
        await tester.pump(const Duration(milliseconds: 700));
        await tocar(find.byTooltip('Gerenciar ocorrência').first);
        await tocar(find.text('Excluir ocorrência'));
        await foto(
          'gerenciar-exclusao',
          'Gerenciar — confirmação de exclusão',
          'RF02, CU08',
        );
        await tocar(find.widgetWithText(TextButton, 'Cancelar'));
        final matches = await real(repo.correspondencias);
        expect(matches, isNotEmpty);
        await ir('/correspondencia/${matches.first.id}');
        await foto(
          'correspondencia',
          'Possível correspondência — imagens relacionadas e confiança',
          'RF05, RF06, CU11, CU12',
          imagens: true,
        );
        await fundo('Ver ocorrência completa');
        await foto(
          'correspondencia-inferior',
          'Possível correspondência — data, local e acesso ao registro',
          'RF05, RF06, CU11, CU12',
        );
        for (var i = 0; i < perfis.length; i++) {
          await usuario(i);
          await ir('/perfil');
          await foto(
            'perfil-$i',
            'Perfil ${perfis[i]} — dados e permissões',
            'RF01, RD01',
          );
          await fundo('Sair da conta');
          await foto(
            'perfil-$i-inferior',
            'Perfil ${perfis[i]} — ações de atualização e logout',
            'RF01, CU02',
          );
          await tocar(find.widgetWithText(Botao, 'Atualizar meus dados'));
          await foto(
            'perfil-$i-edicao',
            'Perfil ${perfis[i]} — edição dos dados',
            'RF01',
          );
          await fundo('Salvar meus dados');
          await foto(
            'perfil-$i-edicao-inferior',
            'Perfil ${perfis[i]} — documento, nova senha e confirmação',
            'RF01',
          );
          await ir('/galeria');
        }
        repo.falha = true;
        await ir('/perfil');
        await ir('/galeria');
        await foto(
          'galeria-falha',
          'Galeria — indisponibilidade e nova tentativa',
          'RNF03, CU03',
          fonte: 'Falha induzida apenas no repositório deste cliente',
        );
        repo.falha = false;
        await ir('/ocorrencia/2147483647');
        await foto(
          'detalhe-inexistente',
          'Detalhe — registro inexistente',
          'RNF03, CU03',
          fonte: 'Resposta 404 real da API',
        );
        await ir('/correspondencia/2147483647');
        await foto(
          'correspondencia-inexistente',
          'Correspondência — resultado indisponível',
          'RNF03, CU12',
          fonte: 'Resposta 404 real da API',
        );
        await ir('/registrar/2147483647');
        await foto(
          'edicao-inexistente',
          'Edição — registro indisponível',
          'RNF03, RF02',
          fonte: 'Resposta 404 real da API',
        );
        await fundo('Salvar alterações');
        await foto(
          'edicao-inexistente-inferior',
          'Edição — mensagem de registro indisponível e ações',
          'RNF03, RF02',
          fonte: 'Resposta 404 real da API',
        );
        expect(tester.takeException(), isNull);
        debugPrint('MIAR_CATALOGO_TOTAL=$seq');
      } finally {
        repo.falha = false;
        repo.vazio = false;
        await tester.pumpWidget(const SizedBox());
        sessao.dispose();
        for (final r in registros) {
          try {
            await real(
              () => http.delete(
                '/ocorrencias/${r['id']}',
                options: Options(
                  headers: {
                    'Authorization':
                        'Bearer ${contas[r['owner'] as int]['token']}',
                  },
                ),
              ),
            );
          } catch (_) {}
        }
        for (final c in contas) {
          try {
            await real(
              () => http.post(
                '/auth/logout',
                options: Options(
                  headers: {'Authorization': 'Bearer ${c['token']}'},
                ),
              ),
            );
          } catch (_) {}
        }
        http.close();
        repo.dio.close(force: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
