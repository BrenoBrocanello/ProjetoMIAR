import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/entidades.dart';
import 'design.dart';
import 'viewmodels.dart';

class CorrespondenciaPage extends StatefulWidget {
  final int id;
  final SessaoViewModel sessao;
  const CorrespondenciaPage(this.id, this.sessao, {super.key});
  @override
  State<CorrespondenciaPage> createState() => _CorrespondenciaPageState();
}

class _CorrespondenciaPageState extends State<CorrespondenciaPage> {
  Correspondencia? c;
  String? erro;
  @override
  void initState() {
    super.initState();
    unawaited(carregar());
  }

  Future<void> carregar() async {
    try {
      final v = await widget.sessao.repository.correspondencia(widget.id);
      if (mounted) {
        setState(() {
          c = v;
          erro = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => erro = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final origem = c == null
        ? null
        : Ocorrencia(Json.from(c!.dados['origem'] as Map));
    final perdido = c == null
        ? null
        : Ocorrencia(Json.from(c!.dados['perdido'] as Map));
    return MiarLayout(
      titulo: 'Correspondência',
      voltar: true,
      sheet: true,
      child: c == null
          ? (erro != null
                ? Mensagem(erro!, erro: true, tentar: carregar)
                : const Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Cartao(
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_none, color: Miar.info),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Possível correspondência encontrada',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              Text(
                                'Para sua ocorrência de ${formatarData(perdido!.data)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'A análise automática de imagens identificou semelhança entre sua ocorrência de animal perdido e outro registro cadastrado.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Miar.gray),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Comparacao(
                          perdido,
                          'Sua ocorrência',
                          widget.sessao,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 48,
                        ),
                        child: Icon(
                          Icons.compare_arrows_rounded,
                          color: Miar.purple,
                        ),
                      ),
                      Expanded(
                        child: _Comparacao(
                          origem!,
                          'Registro compatível',
                          widget.sessao,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Cartao(
                    child: Column(
                      children: [
                        const Text(
                          'PERCENTUAL DE CONFIANÇA',
                          style: TextStyle(
                            fontSize: 11,
                            color: Miar.gray,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${c!.confianca.toStringAsFixed(0)}%',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineLarge?.copyWith(fontSize: 40),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 8,
                            child: LayoutBuilder(
                              builder: (_, constraints) => Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width:
                                      constraints.maxWidth * c!.confianca / 100,
                                  decoration: const BoxDecoration(
                                    gradient: Miar.action,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Análise realizada em ${formatarData(DateTime.parse(c!.dados['data_analise'] as String).toLocal())}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Miar.purple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Registro encontrado em ${origem.cidade}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Botao(
                    'Ver ocorrência completa',
                    onPressed: () => context.push('/ocorrencia/${origem.id}'),
                    icon: Icons.arrow_forward,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

class _Comparacao extends StatelessWidget {
  final Ocorrencia o;
  final String titulo;
  final SessaoViewModel sessao;
  const _Comparacao(this.o, this.titulo, this.sessao);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 145,
          width: double.infinity,
          child: Foto(
            o.foto,
            sessao.repository,
            alignment: Alignment.topCenter,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        titulo,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 6),
      BadgeStatus(o.status),
    ],
  );
}
