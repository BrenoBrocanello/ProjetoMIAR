import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/entidades.dart';
import 'design.dart';
import 'viewmodels.dart';

class DetalhePage extends StatefulWidget {
  final int id;
  final SessaoViewModel sessao;
  const DetalhePage(this.id, this.sessao, {super.key});
  @override
  State<DetalhePage> createState() => _DetalhePageState();
}

class _DetalhePageState extends State<DetalhePage> with WidgetsBindingObserver {
  StreamSubscription<void>? eventos;
  Ocorrencia? o;
  String? erro;
  bool abrindo = false;
  int pagina = 0;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    eventos = widget.sessao.repository.mudancas().listen(
      (_) => unawaited(carregar()),
    );
    unawaited(carregar());
    timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(carregar());
      }
    });
  }

  Future<void> carregar() async {
    try {
      final value = await widget.sessao.repository.ocorrencia(widget.id);
      if (mounted) {
        setState(() {
          o = value;
          erro = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => erro = e.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(carregar());
  }

  @override
  void dispose() {
    timer?.cancel();
    unawaited(eventos?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> contato() async {
    setState(() => abrindo = true);
    try {
      final uri = await widget.sessao.repository.contato(widget.id);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Não foi possível abrir o WhatsApp.');
      }
    } catch (e) {
      if (mounted) informar(context, e.toString());
      unawaited(carregar());
    } finally {
      if (mounted) setState(() => abrindo = false);
    }
  }

  @override
  Widget build(BuildContext context) => MiarLayout(
    titulo: 'Ocorrência',
    voltar: true,
    child: o == null
        ? (erro != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Mensagem(erro!, erro: true, tentar: carregar),
                )
              : const Center(child: CircularProgressIndicator()))
        : RefreshIndicator(
            onRefresh: carregar,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: SizedBox(
                        height: 240,
                        child: Stack(
                          children: [
                            PageView(
                              children: [
                                for (final f in o!.fotos)
                                  Foto(
                                    f['url_storage'] as String,
                                    widget.sessao.repository,
                                    alignment: Alignment.topCenter,
                                  ),
                              ],
                              onPageChanged: (p) => setState(() => pagina = p),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: BadgeStatus(o!.status),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Cartao(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: Text(
                                  '${pagina + 1}/${o!.fotos.length}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Folha(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${o!.especie} · ${o!.porte}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Cartao(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                'Espécie: ${o!.especie}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Cartao(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                'Porte: ${o!.porte}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const _Rotulo('Descrição física'),
                        Text(o!.descricao),
                        const SizedBox(height: 20),
                        const _Rotulo('Estado aparente de saúde'),
                        Text(o!.saude),
                        const Divider(height: 36),
                        _Info(
                          Icons.location_on_outlined,
                          o!.localizacao['endereco'] as String? ?? o!.cidade,
                          o!.cidade,
                        ),
                        const SizedBox(height: 16),
                        _Info(
                          Icons.calendar_today_outlined,
                          'Registrado em ${formatarData(o!.data)}',
                          'por ${(o!.dados['responsavel'] as Map)['nome']}',
                        ),
                        const SizedBox(height: 24),
                        if (erro != null)
                          Mensagem(erro!, erro: true, tentar: carregar),
                        if (o!.podeContatar)
                          Botao(
                            'Falar no WhatsApp',
                            ocupado: abrindo,
                            onPressed: contato,
                            icon: Icons.open_in_new_rounded,
                          )
                        else
                          const Mensagem(
                            'Ocorrência encerrada. O contato público está desabilitado.',
                          ),
                        if (o!.responsavelId == widget.sessao.usuario?.id)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Botao(
                              'Alterar minha ocorrência',
                              secundario: true,
                              icon: Icons.edit_outlined,
                              onPressed: () async {
                                await context.push('/registrar/${o!.id}');
                                if (mounted) unawaited(carregar());
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}

class _Rotulo extends StatelessWidget {
  final String text;
  const _Rotulo(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
        color: Miar.gray,
      ),
    ),
  );
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _Info(this.icon, this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 22, color: Miar.purple),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );
}

class RegistrarPage extends StatefulWidget {
  final SessaoViewModel sessao;
  final int? id;
  const RegistrarPage(this.sessao, {super.key, this.id});
  @override
  State<RegistrarPage> createState() => _RegistrarPageState();
}

class _RegistrarPageState extends State<RegistrarPage> {
  final form = GlobalKey<FormState>();
  final campos = {
    for (final k in [
      'especie',
      'porte',
      'descricao_fisica',
      'estado_saude',
      'cidade',
      'estado',
      'endereco',
      'numero_whatsapp',
    ])
      k: TextEditingController(),
  };
  String status = 'Encontrado';
  List<FotografiaEnvio> novas = [];
  List<Json> mantidas = [];
  double? latitude, longitude;
  bool carregando = false, ocupado = false, gps = false, fotosOcupadas = false;
  String? erro;
  @override
  void initState() {
    super.initState();
    campos['numero_whatsapp']!.text =
        widget.sessao.usuario?.dados['telefone'] as String? ?? '';
    if (widget.id != null) {
      carregando = true;
      unawaited(carregar());
    }
    unawaited(recuperarFotos());
  }

  Future<void> recuperarFotos() async {
    try {
      final data = await ImagePicker().retrieveLostData();
      if (!data.isEmpty && data.files != null) {
        await adicionar(data.files!);
      }
    } catch (_) {
      /* A seleção normal continua disponível. */
    }
  }

  Future<void> carregar() async {
    try {
      final o = await widget.sessao.repository.ocorrencia(
        widget.id!,
        editar: true,
      );
      for (final key in [
        'especie',
        'porte',
        'descricao_fisica',
        'estado_saude',
      ]) {
        campos[key]!.text = o.dados[key] as String;
      }
      campos['cidade']!.text = o.cidade;
      campos['estado']!.text = o.localizacao['estado'] as String? ?? '';
      campos['endereco']!.text = o.localizacao['endereco'] as String? ?? '';
      campos['numero_whatsapp']!.text =
          (o.dados['contato'] as Map)['numero_whatsapp'] as String;
      if (mounted) {
        setState(() {
          mantidas = o.fotos;
          status = o.status;
          latitude = o.latitude;
          longitude = o.longitude;
        });
      }
    } catch (e) {
      if (mounted) setState(() => erro = e.toString());
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  void dispose() {
    for (final c in campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> fotografias() async {
    final camera = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: Miar.purple,
              ),
              title: const Text('Tirar fotografia'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Miar.purple,
              ),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (camera == null || !mounted) return;
    setState(() => fotosOcupadas = true);
    try {
      final picker = ImagePicker();
      final List<XFile> files;
      if (camera) {
        final file = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 90,
        );
        files = file == null ? [] : [file];
      } else {
        files = await picker.pickMultiImage(
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 90,
        );
      }
      await adicionar(files);
    } catch (_) {
      if (mounted) {
        informar(
          context,
          'Não foi possível acessar as fotografias. Confira a permissão de câmera ou galeria.',
        );
      }
    } finally {
      if (mounted) setState(() => fotosOcupadas = false);
    }
  }

  Future<void> adicionar(List<XFile> files) async {
    for (final f in files) {
      if (novas.length + mantidas.length >= 6) {
        if (mounted) {
          informar(context, 'Mantenha até seis fotografias por ocorrência.');
        }
        break;
      }
      final bytes = await f.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1600,
        minHeight: 1600,
        quality: 85,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (mounted) {
        setState(
          () => novas.add(
            FotografiaEnvio('foto-${novas.length + 1}.jpg', compressed),
          ),
        );
      }
    }
  }

  Future<void> localizar() async {
    setState(() => gps = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Ative a localização do aparelho para obter o GPS.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Autorize o acesso à localização nas configurações do aparelho.',
        );
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
      if (mounted) {
        setState(() {
          latitude = p.latitude;
          longitude = p.longitude;
        });
      }
    } catch (e) {
      if (mounted) {
        informar(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => gps = false);
    }
  }

  Future<void> salvar() async {
    if (!form.currentState!.validate()) return;
    if (novas.isEmpty && mantidas.isEmpty) {
      informar(context, 'Adicione pelo menos uma fotografia.');
      return;
    }
    if (latitude == null || longitude == null) {
      informar(context, 'Obtenha a localização por GPS antes de cadastrar.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      ocupado = true;
      erro = null;
    });
    final Json data = {
      for (final k in [
        'especie',
        'porte',
        'descricao_fisica',
        'estado_saude',
        'numero_whatsapp',
      ])
        k: campos[k]!.text.trim(),
      'status_ocorrencia': status,
      'localizacao': {
        'latitude': latitude,
        'longitude': longitude,
        'cidade': campos['cidade']!.text.trim(),
        'estado': campos['estado']!.text.trim().toUpperCase(),
        'endereco': campos['endereco']!.text.trim(),
      },
      if (widget.id != null)
        'fotos_mantidas': mantidas.map((f) => f['id_foto']).toList(),
    };
    try {
      final o = await widget.sessao.repository.salvarOcorrencia(
        data,
        novas,
        id: widget.id,
      );
      await widget.sessao.atualizarContexto();
      if (mounted) {
        informar(
          context,
          'Ocorrência ${widget.id == null ? 'cadastrada' : 'atualizada'}.',
        );
        context.go('/ocorrencia/${o.id}');
      }
    } catch (e) {
      if (mounted) setState(() => erro = e.toString());
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => MiarLayout(
    titulo: widget.id == null ? 'Nova ocorrência' : 'Alterar ocorrência',
    voltar: true,
    sheet: true,
    child: carregando
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: AbsorbPointer(
              absorbing: ocupado,
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Fotografias',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < mantidas.length; i++)
                          _FotoRemovivel(
                            onRemove: () =>
                                setState(() => mantidas.removeAt(i)),
                            child: Foto(
                              mantidas[i]['url_storage'] as String,
                              widget.sessao.repository,
                            ),
                          ),
                        for (var i = 0; i < novas.length; i++)
                          _FotoRemovivel(
                            onRemove: () => setState(() => novas.removeAt(i)),
                            child: Image.memory(
                              Uint8List.fromList(novas[i].bytes),
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (novas.length + mantidas.length < 6)
                          SizedBox(
                            width: 88,
                            height: 88,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Miar.lilac),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: fotosOcupadas ? null : fotografias,
                              child: fotosOcupadas
                                  ? const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    )
                                  : const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_rounded),
                                        Text(
                                          'Adicionar',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Campo(
                      controller: campos['especie']!,
                      label: 'Espécie',
                      hint: 'Ex.: Cão',
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: portes.contains(campos['porte']!.text)
                          ? campos['porte']!.text
                          : null,
                      decoration: const InputDecoration(labelText: 'Porte'),
                      items: portes
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      validator: (p) => p == null ? 'Selecione o porte.' : null,
                      onChanged: (p) => campos['porte']!.text = p ?? '',
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Status da ocorrência',
                      ),
                      items: statusOcorrencia
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (s) => setState(() => status = s!),
                    ),
                    const SizedBox(height: 20),
                    Campo(
                      controller: campos['descricao_fisica']!,
                      label: 'Descrição física',
                      linhas: 3,
                      hint: 'Pelagem, cor e características do animal',
                    ),
                    Campo(
                      controller: campos['estado_saude']!,
                      label: 'Estado aparente de saúde',
                      hint: 'Descreva a condição aparente do animal',
                    ),
                    Campo(controller: campos['cidade']!, label: 'Cidade'),
                    Campo(
                      controller: campos['estado']!,
                      label: 'Estado (UF)',
                      obrigatorio: false,
                    ),
                    Campo(
                      controller: campos['endereco']!,
                      label: 'Endereço',
                      obrigatorio: false,
                    ),
                    Text(
                      'Localização',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Cartao(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Miar.purple,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  latitude == null
                                      ? 'Localização ainda não obtida'
                                      : '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: gps ? null : localizar,
                            icon: gps
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              latitude == null
                                  ? 'Obter localização por GPS'
                                  : 'Atualizar localização por GPS',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Campo(
                      controller: campos['numero_whatsapp']!,
                      label: 'WhatsApp para contato',
                      tipo: TextInputType.phone,
                      icon: Icons.phone_outlined,
                    ),
                    if (erro != null) Mensagem(erro!, erro: true),
                    Botao(
                      widget.id == null
                          ? 'Cadastrar ocorrência'
                          : 'Salvar alterações',
                      onPressed: fotosOcupadas || gps ? null : salvar,
                      ocupado: ocupado,
                      icon: Icons.arrow_forward,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
  );
}

class _FotoRemovivel extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;
  const _FotoRemovivel({required this.child, required this.onRemove});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 88,
    height: 88,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
        Positioned(
          right: 0,
          top: 0,
          child: Material(
            color: Colors.white.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(16),
            child: IconButton(
              tooltip: 'Remover fotografia',
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
        ),
      ],
    ),
  );
}
