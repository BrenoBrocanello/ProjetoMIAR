import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../domain/entidades.dart';
import 'design.dart';
import 'viewmodels.dart';

class GerenciarPage extends StatefulWidget {
  final SessaoViewModel sessao;
  const GerenciarPage(this.sessao, {super.key});
  @override
  State<GerenciarPage> createState() => _GerenciarPageState();
}

class _GerenciarPageState extends State<GerenciarPage> {
  late final vm = ListaViewModel(widget.sessao.repository, minhas: true);
  @override
  void initState() {
    super.initState();
    unawaited(vm.carregar());
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Future<void> atualizar() async {
    await vm.carregar();
    await widget.sessao.atualizarContexto();
  }

  Future<void> acao(String acao, Ocorrencia o) async {
    if (acao == 'editar') {
      await context.push('/registrar/${o.id}');
      if (mounted) await atualizar();
      return;
    }
    if (acao == 'status') {
      await mostrarStatus(context, o, widget.sessao);
      if (mounted) await atualizar();
      return;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir ocorrência?'),
        content: Text(
          'A ocorrência de ${o.especie.toLowerCase()} deixará de aparecer nas consultas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Miar.danger)),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await widget.sessao.repository.excluir(o.id);
      if (mounted) {
        informar(context, 'Ocorrência excluída.');
        await atualizar();
      }
    } catch (e) {
      if (mounted) informar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: vm,
    builder: (context, _) => MiarLayout(
      titulo: 'Minhas ocorrências',
      sessao: widget.sessao,
      destino: '/gerenciar',
      child: RefreshIndicator(
        onRefresh: atualizar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(
              'Gerencie os registros sob sua responsabilidade.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            if (vm.erro != null)
              Mensagem(vm.erro!, erro: true, tentar: atualizar),
            if (vm.carregando && vm.items.isEmpty)
              const Center(child: CircularProgressIndicator()),
            if (!vm.carregando && vm.items.isEmpty && vm.erro == null)
              const Mensagem('Você ainda não possui ocorrências cadastradas.'),
            for (final o in vm.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Cartao(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/ocorrencia/${o.id}'),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 72,
                            height: 80,
                            child: Foto(o.foto, widget.sessao.repository),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push('/ocorrencia/${o.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BadgeStatus(o.status),
                              const SizedBox(height: 6),
                              Text(
                                '${o.especie} · ${o.porte}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Criada em ${formatarData(o.data)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Gerenciar ocorrência',
                        onSelected: (v) => acao(v, o),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'status',
                            child: Text('Atualizar status'),
                          ),
                          const PopupMenuItem(
                            value: 'editar',
                            child: Text('Alterar dados'),
                          ),
                          const PopupMenuItem(
                            value: 'excluir',
                            child: Text(
                              'Excluir ocorrência',
                              style: TextStyle(color: Miar.danger),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (vm.temMais)
              Botao(
                'Carregar mais',
                secundario: true,
                ocupado: vm.carregando,
                onPressed: () => vm.carregar(mais: true),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> mostrarStatus(
  BuildContext context,
  Ocorrencia o,
  SessaoViewModel sessao,
) async {
  var status = o.status;
  bool ocupado = false;
  String? erro;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Atualizar status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${o.especie} · ${o.porte} · registrada em ${formatarData(o.data)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: [
                  for (final s in statusOcorrencia)
                    ChoiceChip(
                      label: BadgeStatus(s),
                      selected: status == s,
                      showCheckmark: false,
                      padding: const EdgeInsets.all(3),
                      selectedColor: Colors.white,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: status == s
                            ? Miar.purple
                            : Miar.ink.withValues(alpha: .08),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: ocupado ? null : (_) => set(() => status = s),
                    ),
                ],
              ),
              if (erro != null) Mensagem(erro!, erro: true),
              const SizedBox(height: 24),
              Botao(
                'Salvar alteração',
                ocupado: ocupado,
                onPressed: () async {
                  set(() {
                    ocupado = true;
                    erro = null;
                  });
                  try {
                    await sessao.repository.alterarStatus(o.id, status);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      set(() {
                        ocupado = false;
                        erro = e.toString();
                      });
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
