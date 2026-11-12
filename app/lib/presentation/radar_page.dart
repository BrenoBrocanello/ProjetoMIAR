import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/entidades.dart';
import 'design.dart';
import 'galeria_page.dart';
import 'viewmodels.dart';

class RadarPage extends StatefulWidget {
  final SessaoViewModel sessao;
  const RadarPage(this.sessao, {super.key});
  @override
  State<RadarPage> createState() => _RadarPageState();
}

class _RadarPageState extends State<RadarPage> {
  late final vm = ListaViewModel(widget.sessao.repository, radar: true);
  final map = MapController();
  int? selecionadaId;
  int mapaVersao = 0;
  Ocorrencia? get selecionada {
    for (final o in vm.items) {
      if (o.id == selecionadaId) return o;
    }
    return null;
  }

  set selecionada(Ocorrencia? o) => selecionadaId = o?.id;
  bool mapaFalhou = false;
  Future<void> atualizarMapa() async {
    setState(() {
      mapaFalhou = false;
      mapaVersao++;
    });
    await vm.carregar();
  }

  @override
  void initState() {
    super.initState();
    unawaited(vm.carregar());
  }

  @override
  void dispose() {
    vm.dispose();
    map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: vm,
    builder: (context, _) => MiarLayout(
      titulo: 'Radar de Resgate',
      sessao: widget.sessao,
      destino: '/radar',
      actions: [
        IconButton(
          tooltip: 'Atualizar radar',
          onPressed: atualizarMapa,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: Column(
        children: [
          StatusChips(
            atual: vm.filtros['status'] as String?,
            onChange: (s) {
              selecionada = null;
              unawaited(vm.filtrar({'status': ?s}));
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                if (vm.carregando && vm.items.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  FlutterMap(
                    mapController: map,
                    options: MapOptions(
                      initialCenter: vm.items.isEmpty
                          ? const LatLng(-23.1857, -46.8978)
                          : LatLng(
                              vm.items.first.latitude,
                              vm.items.first.longitude,
                            ),
                      initialZoom: 12,
                    ),
                    children: [
                      TileLayer(
                        key: ValueKey(mapaVersao),
                        urlTemplate: widget.sessao.repository.fotoUrl(
                          '/mapa/{z}/{x}/{y}',
                        ),
                        tileProvider: MiarTileProvider(),
                        userAgentPackageName: 'br.com.miar.miar',
                        errorTileCallback: (tile, error, stack) {
                          if (!mapaFalhou) {
                            if (mounted) setState(() => mapaFalhou = true);
                          }
                        },
                      ),
                      MarkerLayer(
                        markers: [
                          for (final o in vm.items)
                            Marker(
                              point: LatLng(o.latitude, o.longitude),
                              width: 48,
                              height: 56,
                              child: Semantics(
                                button: true,
                                label: '${o.especie}, ${o.status}, ${o.cidade}',
                                child: GestureDetector(
                                  onTap: () => setState(() => selecionada = o),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: Miar.action,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Miar.purple.withValues(
                                            alpha: .2,
                                          ),
                                          blurRadius: 14,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.location_on_outlined,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            'OpenStreetMap contributors',
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://www.openstreetmap.org/copyright',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (vm.erro != null || mapaFalhou)
                  Positioned(
                    top: 12,
                    left: 24,
                    right: 24,
                    child: Mensagem(
                      vm.erro ??
                          'Não foi possível carregar o mapa. Verifique sua conexão.',
                      erro: true,
                      tentar: () => unawaited(atualizarMapa()),
                    ),
                  ),
                if (!vm.carregando && vm.items.isEmpty && vm.erro == null)
                  const Positioned(
                    bottom: 30,
                    left: 24,
                    right: 24,
                    child: Mensagem(
                      'Nenhuma ocorrência disponível para estes filtros.',
                    ),
                  ),
                if (selecionada case final o?)
                  Positioned(
                    bottom: 32,
                    left: 24,
                    right: 24,
                    child: GestureDetector(
                      onTap: () => context.push('/ocorrencia/${o.id}'),
                      child: Cartao(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 66,
                                height: 74,
                                child: Foto(o.foto, widget.sessao.repository),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  BadgeStatus(o.status),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${o.especie} · ${o.porte}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    o.cidade,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
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
        ],
      ),
    ),
  );
}

class MiarTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      NetworkImage(getTileUrl(coordinates, options));
}
