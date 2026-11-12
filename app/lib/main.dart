import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'data/api_repository.dart';
import 'data/notificacoes.dart';
import 'presentation/design.dart';
import 'presentation/viewmodels.dart';
import 'presentation/auth_pages.dart';
import 'presentation/galeria_page.dart';
import 'presentation/ocorrencia_pages.dart';
import 'presentation/gerenciar_page.dart';
import 'presentation/perfil_page.dart';
import 'presentation/radar_page.dart';
import 'presentation/correspondencia_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  final repo = ApiRepository();
  final sessao = SessaoViewModel(repo);
  repo.sessaoExpirada = sessao.expirar;
  runApp(MiarApp(sessao: sessao, avisos: AvisosDispositivo(repo)));
  unawaited(sessao.iniciar());
}

class MiarApp extends StatefulWidget {
  final SessaoViewModel sessao;
  final AvisosDispositivo? avisos;
  const MiarApp({super.key, required this.sessao, this.avisos});
  @override
  State<MiarApp> createState() => _MiarAppState();
}

class _MiarAppState extends State<MiarApp> {
  late final GoRouter router;
  int? usuarioNotificacoes, pendenteAbrir;
  int ultimaVersao = 0;
  @override
  void initState() {
    super.initState();
    final s = widget.sessao;
    router = GoRouter(
      initialLocation: '/galeria',
      refreshListenable: s,
      redirect: (context, state) {
        if (s.iniciando) {
          return state.matchedLocation == '/iniciando' ? null : '/iniciando';
        }
        final auth =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/cadastro';
        if (s.usuario == null) return auth ? null : '/login';
        if (auth || state.matchedLocation == '/iniciando') return '/galeria';
        if (state.matchedLocation == '/radar' && !s.usuario!.podeVerRadar) {
          return '/galeria';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/iniciando',
          builder: (_, _) => const MiarLayout(
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        GoRoute(path: '/login', builder: (_, _) => LoginPage(s)),
        GoRoute(path: '/cadastro', builder: (_, _) => CadastroPage(s)),
        GoRoute(path: '/galeria', builder: (_, _) => GaleriaPage(s)),
        GoRoute(path: '/radar', builder: (_, _) => RadarPage(s)),
        GoRoute(path: '/registrar', builder: (_, _) => RegistrarPage(s)),
        GoRoute(
          path: '/registrar/:id',
          builder: (_, state) =>
              RegistrarPage(s, id: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/ocorrencia/:id',
          builder: (_, state) =>
              DetalhePage(int.parse(state.pathParameters['id']!), s),
        ),
        GoRoute(path: '/gerenciar', builder: (_, _) => GerenciarPage(s)),
        GoRoute(path: '/perfil', builder: (_, _) => PerfilPage(s)),
        GoRoute(
          path: '/correspondencia/:id',
          builder: (_, state) =>
              CorrespondenciaPage(int.parse(state.pathParameters['id']!), s),
        ),
      ],
    );
    widget.avisos?.abrir = (id) {
      if (s.usuario != null) {
        router.push('/correspondencia/$id');
      } else {
        pendenteAbrir = id;
      }
    };
    s.addListener(mudouSessao);
    WidgetsBinding.instance.addPostFrameCallback((_) => mudouSessao());
  }

  void mudouSessao() {
    if (ultimaVersao != widget.sessao.versaoDados) {
      ultimaVersao = widget.sessao.versaoDados;
      unawaited(widget.avisos?.consultar() ?? Future.value());
    }
    final id = widget.sessao.usuario?.id;
    if (id != usuarioNotificacoes) {
      usuarioNotificacoes = id;
      if (id != null) {
        unawaited(
          widget.avisos?.iniciarSessao().catchError((_) {}) ?? Future.value(),
        );
      } else {
        unawaited(widget.avisos?.parar().catchError((_) {}) ?? Future.value());
      }
    }
    if (id != null && pendenteAbrir != null) {
      final c = pendenteAbrir!;
      pendenteAbrir = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) router.push('/correspondencia/$c');
      });
    }
  }

  @override
  void dispose() {
    widget.sessao.removeListener(mudouSessao);
    widget.avisos?.dispose();
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.sessao,
    builder: (context, _) => MaterialApp.router(
      title: 'MIAR',
      debugShowCheckedModeBanner: false,
      theme: Miar.theme,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    ),
  );
}
