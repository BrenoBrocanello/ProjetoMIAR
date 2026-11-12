import 'dart:async';
import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/miar_repository.dart';
import 'api_repository.dart';

@pragma('vm:entry-point')
void avisosHeadless(HeadlessEvent task) async {
  if (task.timeout) {
    BackgroundFetch.finish(task.taskId);
    return;
  }
  try {
    final repo = ApiRepository();
    if (await repo.restaurarSessao() != null) {
      final avisos = AvisosDispositivo(repo);
      await avisos.inicializar();
      await avisos.consultar();
    }
  } catch (_) {
    /* RNF03: próxima execução tenta novamente, sem confirmar emissão. */
  } finally {
    BackgroundFetch.finish(task.taskId);
  }
}

class AvisosDispositivo with WidgetsBindingObserver {
  final MiarRepository repository;
  final plugin = FlutterLocalNotificationsPlugin();
  void Function(int)? abrir;
  Timer? _timer;
  bool _consultando = false, _inicializado = false;
  final _emitidos = <int>{};
  int _geracao = 0;
  AvisosDispositivo(this.repository);
  Future<void> inicializar() async {
    if (_inicializado) return;
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_miar'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final id = int.tryParse(response.payload ?? '');
        if (id != null) abrir?.call(id);
      },
    );
    _inicializado = true;
    final launch = await plugin.getNotificationAppLaunchDetails();
    final id = int.tryParse(launch?.notificationResponse?.payload ?? '');
    if (launch?.didNotificationLaunchApp == true && id != null) abrir?.call(id);
  }

  Future<void> iniciarSessao() async {
    await inicializar();
    if (Platform.isAndroid) {
      await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
    if (Platform.isIOS) {
      await plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        startOnBoot: true,
        enableHeadless: true,
        requiredNetworkType: NetworkType.ANY,
      ),
      (task) async {
        try {
          await consultar();
        } finally {
          await BackgroundFetch.finish(task);
        }
      },
      (task) async => BackgroundFetch.finish(task),
    );
    BackgroundFetch.registerHeadlessTask(avisosHeadless);
    WidgetsBinding.instance.addObserver(this);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(consultar());
      }
    });
    await consultar();
  }

  Future<void> consultar() async {
    if (_consultando || !_inicializado) return;
    _consultando = true;
    final geracao = _geracao;
    try {
      if (Platform.isAndroid &&
          await plugin
                  .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin
                  >()
                  ?.areNotificationsEnabled() !=
              true) {
        return;
      }
      if (Platform.isIOS &&
          (await plugin
                      .resolvePlatformSpecificImplementation<
                        IOSFlutterLocalNotificationsPlugin
                      >()
                      ?.checkPermissions())
                  ?.isEnabled !=
              true) {
        return;
      }
      for (final c in await repository.correspondencias()) {
        if (geracao != _geracao) return;
        if (!c.pendente) continue;
        if (!_emitidos.contains(c.id)) {
          await plugin.show(
            id: c.id,
            title: 'Possível correspondência encontrada',
            body:
                'Uma fotografia se parece com a da sua ocorrência de animal perdido. Toque para conferir.',
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'correspondencias',
                'Possíveis correspondências',
                channelDescription: 'Avisos de semelhança com animais perdidos',
                importance: Importance.high,
                priority: Priority.high,
                icon: 'ic_stat_miar',
              ),
              iOS: DarwinNotificationDetails(),
            ),
            payload: c.id.toString(),
          );
          _emitidos.add(c.id);
        }
        await repository.confirmarAviso(c.id);
      }
    } catch (_) {
      /* Sem permissão ou serviço mantém Pendente, sem entrega fictícia. */
    } finally {
      _consultando = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(consultar());
  }

  Future<void> parar() async {
    _geracao++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _emitidos.clear();
    await BackgroundFetch.stop();
    await plugin.cancelAll();
  }

  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
