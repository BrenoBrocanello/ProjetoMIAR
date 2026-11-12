import 'package:flutter/foundation.dart';
import 'dart:async';

import '../domain/entidades.dart';
import '../domain/miar_repository.dart';

class SessaoViewModel extends ChangeNotifier {
  final MiarRepository repository;
  Usuario? usuario;
  bool iniciando = true;
  String? erroInicial;
  int minhasTotal = 0;
  List<Correspondencia> avisos = [];
  StreamSubscription<void>? _eventos;
  int versaoDados = 0;
  SessaoViewModel(this.repository);
  Future<void> iniciar() async {
    iniciando = true;
    erroInicial = null;
    notifyListeners();
    try {
      usuario = await repository.restaurarSessao();
    } catch (e) {
      erroInicial = e.toString();
    }
    iniciando = false;
    notifyListeners();
    if (usuario != null) {
      _escutar();
      await atualizarContexto();
    }
  }

  Future<void> entrar(String email, String senha) async {
    usuario = await repository.entrar(email.trim(), senha);
    _escutar();
    erroInicial = null;
    notifyListeners();
    await atualizarContexto();
  }

  Future<void> sair() async {
    await repository.sair();
    expirar();
  }

  void expirar() {
    unawaited(_eventos?.cancel());
    _eventos = null;
    usuario = null;
    minhasTotal = 0;
    avisos = [];
    notifyListeners();
  }

  Future<void> atualizarPerfil(Json dados) async {
    usuario = await repository.atualizarPerfil(dados);
    notifyListeners();
  }

  void _escutar() {
    unawaited(_eventos?.cancel());
    _eventos = repository.mudancas().listen((_) {
      versaoDados++;
      notifyListeners();
      unawaited(atualizarContexto());
    });
  }

  @override
  void dispose() {
    unawaited(_eventos?.cancel());
    super.dispose();
  }

  Future<void> atualizarContexto() async {
    if (usuario == null) return;
    final id = usuario!.id;
    try {
      final own = await repository.ocorrencias(minhas: true);
      final matches = await repository.correspondencias();
      if (usuario?.id != id) return;
      minhasTotal = own.total;
      avisos = matches;
      notifyListeners();
    } catch (_) {
      /* O erro das consultas visíveis é apresentado pela respectiva tela. */
    }
  }
}

class ListaViewModel extends ChangeNotifier {
  StreamSubscription<void>? _eventos;
  final MiarRepository repository;
  final bool minhas;
  final bool radar;
  List<Ocorrencia> items = [];
  int total = 0, pagina = 0, _request = 0;
  bool carregando = false;
  String? erro;
  Json filtros = {};
  ListaViewModel(this.repository, {this.minhas = false, this.radar = false}) {
    _eventos = repository.mudancas().listen(
      (_) => unawaited(carregar(silencioso: true)),
    );
  }
  bool get temMais => items.length < total;
  Future<void> carregar({bool mais = false, bool silencioso = false}) async {
    if (mais && (carregando || !temMais)) return;
    final request = ++_request;
    final next = mais ? pagina + 1 : 0;
    if (!silencioso) carregando = true;
    erro = null;
    notifyListeners();
    try {
      final data = await repository.ocorrencias(
        filtros: filtros,
        minhas: minhas,
        radar: radar,
        pagina: next,
      );
      if (request != _request) return;
      items = mais ? [...items, ...data.items] : data.items;
      total = data.total;
      pagina = next;
    } catch (e) {
      if (request == _request) erro = e.toString();
    } finally {
      if (request == _request) {
        carregando = false;
        notifyListeners();
      }
    }
  }

  Future<void> filtrar(Json valor) {
    filtros = Busca.fromJson(valor).toJson();
    return carregar();
  }

  @override
  void dispose() {
    _request++;
    unawaited(_eventos?.cancel());
    super.dispose();
  }
}
