import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../domain/entidades.dart';
import 'design.dart';
import 'viewmodels.dart';

class GaleriaPage extends StatefulWidget {
  final SessaoViewModel sessao;
  const GaleriaPage(this.sessao, {super.key});
  @override
  State<GaleriaPage> createState() => _GaleriaPageState();
}

class _GaleriaPageState extends State<GaleriaPage> with WidgetsBindingObserver {
  late final ListaViewModel vm;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    vm = ListaViewModel(widget.sessao.repository);
    unawaited(vm.carregar());
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(vm.carregar(silencioso: true));
        unawaited(widget.sessao.atualizarContexto());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(vm.carregar(silencioso: true));
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    vm.dispose();
    super.dispose();
  }

  Future<void> filtros() async {
    final result = await mostrarFiltros(context, vm.filtros);
    if (result != null && mounted) await vm.filtrar(result);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: vm,
    builder: (context, _) => MiarLayout(
      titulo: 'Ocorrências',
      sessao: widget.sessao,
      destino: '/galeria',
      actions: [
        IconButton(
          tooltip: 'Filtrar ocorrências',
          onPressed: filtros,
          icon: Badge(
            isLabelVisible: vm.filtros.isNotEmpty,
            child: const Icon(Icons.tune_rounded),
          ),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          await vm.carregar();
          await widget.sessao.atualizarContexto();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: StatusChips(
                  atual: vm.filtros['status'] as String?,
                  onChange: (s) {
                    final f = {...vm.filtros};
                    if (s == null) {
                      f.remove('status');
                    } else {
                      f['status'] = s;
                    }
                    unawaited(vm.filtrar(f));
                  },
                ),
              ),
            ),
            if (widget.sessao.avisos.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      for (final c in widget.sessao.avisos)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () =>
                                context.push('/correspondencia/${c.id}'),
                            child: Cartao(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Miar.info,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Possível correspondência encontrada',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Miar.purple,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (vm.erro != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Mensagem(vm.erro!, erro: true, tentar: vm.carregar),
                ),
              ),
            if (vm.carregando && vm.items.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!vm.carregando && vm.items.isEmpty && vm.erro == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Mensagem(
                    vm.filtros.isEmpty
                        ? 'Nenhuma ocorrência cadastrada.'
                        : 'Nenhuma ocorrência corresponde aos filtros.',
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final textScale = MediaQuery.textScalerOf(context).scale(1);
                  final columns =
                      constraints.crossAxisExtent < 320 || textScale > 1.4
                      ? 1
                      : 2;
                  return SliverGrid.builder(
                    itemCount: vm.items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      mainAxisExtent: columns == 1
                          ? 350
                          : 300 + ((textScale - 1).clamp(0, 1) * 80),
                    ),
                    itemBuilder: (context, i) =>
                        CardOcorrencia(vm.items[i], widget.sessao),
                  );
                },
              ),
            ),
            if (vm.temMais && !vm.radar)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Botao(
                    'Carregar mais',
                    secundario: true,
                    ocupado: vm.carregando,
                    onPressed: () => vm.carregar(mais: true),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class StatusChips extends StatelessWidget {
  final String? atual;
  final void Function(String?) onChange;
  const StatusChips({super.key, this.atual, required this.onChange});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      children: [
        for (final s in [null, ...statusOcorrencia])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(s ?? 'Todos'),
              selected: atual == s,
              showCheckmark: false,
              backgroundColor: Colors.white.withValues(alpha: .72),
              selectedColor: Miar.lilac.withValues(alpha: .65),
              side: BorderSide.none,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: atual == s ? Miar.ink : Miar.gray,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (_) => onChange(s),
            ),
          ),
      ],
    ),
  );
}

class CardOcorrencia extends StatelessWidget {
  final Ocorrencia o;
  final SessaoViewModel sessao;
  const CardOcorrencia(this.o, this.sessao, {super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${o.especie}, ${o.porte}, ${o.status}, ${o.cidade}',
    child: Material(
      color: Colors.white.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/ocorrencia/${o.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Foto(
                    o.foto,
                    sessao.repository,
                    alignment: Alignment.topCenter,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: BadgeStatus(o.status),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${o.especie} · ${o.porte}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    o.descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Miar.purple,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          o.cidade,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Miar.gray,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formatarData(o.data),
                    style: const TextStyle(fontSize: 11, color: Miar.gray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<Json?> mostrarFiltros(BuildContext context, Json atuais) async {
  final especie = TextEditingController(text: atuais['especie'] as String?),
      porte = TextEditingController(text: atuais['porte'] as String?),
      cidade = TextEditingController(text: atuais['cidade'] as String?);
  String? status = atuais['status'] as String?;
  final result = await showModalBottomSheet<Json>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filtrar ocorrências',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...statusOcorrencia.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s)),
                  ),
                ],
                onChanged: (s) => set(() => status = s),
              ),
              const SizedBox(height: 16),
              Campo(
                controller: especie,
                label: 'Espécie',
                hint: 'Ex.: Cão',
                obrigatorio: false,
              ),
              Campo(
                controller: porte,
                label: 'Porte',
                hint: 'Ex.: Médio',
                obrigatorio: false,
              ),
              Campo(controller: cidade, label: 'Cidade', obrigatorio: false),
              Botao(
                'Aplicar filtros',
                onPressed: () => Navigator.pop(context, <String, dynamic>{
                  'status': ?status,
                  if (especie.text.trim().isNotEmpty)
                    'especie': especie.text.trim(),
                  if (porte.text.trim().isNotEmpty) 'porte': porte.text.trim(),
                  if (cidade.text.trim().isNotEmpty)
                    'cidade': cidade.text.trim(),
                }),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, <String, dynamic>{}),
                child: const Text('Limpar filtros'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  // Aguarda a remoção da rota para não descartar controladores durante a animação.
  Future<void>.delayed(const Duration(milliseconds: 400), () {
    especie.dispose();
    porte.dispose();
    cidade.dispose();
  });
  return result;
}
