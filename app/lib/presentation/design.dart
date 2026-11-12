import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/miar_repository.dart';
import 'viewmodels.dart';

class Miar {
  static const blue = Color(0xFF8AB8FF),
      lilac = Color(0xFFB9A1FF),
      pink = Color(0xFFF2B5EB),
      mint = Color(0xFFA4F4D4);
  static const purple = Color(0xFF7C3AED),
      ink = Color(0xFF180825),
      gray = Color(0xFF77789C);
  static const danger = Color(0xFFC2437A),
      success = Color(0xFF2F9E78),
      info = Color(0xFF3B6FD4),
      warning = Color(0xFF9A6A1F);
  static const aurora = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, lilac, pink, mint],
    stops: [0, .38, .7, 1],
  );
  static const action = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [blue, lilac, pink, mint],
    stops: [0, .3, .62, 1],
  );
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Outfit',
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: purple,
      surface: Colors.white,
      onSurface: ink,
      error: danger,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -.6,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -.4,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.55, color: ink),
      bodyMedium: TextStyle(fontSize: 15, height: 1.55, color: ink),
      bodySmall: TextStyle(fontSize: 13, height: 1.45, color: gray),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: .72),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      hintStyle: const TextStyle(color: gray, fontWeight: FontWeight.w400),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: ink.withValues(alpha: .08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: ink.withValues(alpha: .08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: purple.withValues(alpha: .45),
          width: 1.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: purple,
        minimumSize: const Size(44, 44),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: purple,
        minimumSize: const Size(48, 48),
      ),
    ),
    dividerColor: ink.withValues(alpha: .08),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

class Aurora extends StatelessWidget {
  const Aurora({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(gradient: Miar.aurora),
    child: Stack(
      children: [
        Positioned.fill(
          child: ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: const Stack(
                children: [
                  Positioned(top: -60, left: -60, child: _Blob(Miar.blue, 300)),
                  Positioned(
                    top: 240,
                    right: -100,
                    child: _Blob(Miar.pink, 340),
                  ),
                  Positioned(
                    bottom: -60,
                    left: -60,
                    child: _Blob(Miar.mint, 320),
                  ),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    ),
  );
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob(this.color, this.size);
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size * .9,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .4),
      borderRadius: BorderRadius.circular(size * .45),
    ),
  );
}

class MiarLayout extends StatelessWidget {
  final Widget child;
  final String? titulo;
  final bool voltar, sheet;
  final SessaoViewModel? sessao;
  final String? destino;
  final List<Widget>? actions;
  const MiarLayout({
    super.key,
    required this.child,
    this.titulo,
    this.voltar = false,
    this.sheet = false,
    this.sessao,
    this.destino,
    this.actions,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Aurora(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                if (titulo != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(voltar ? 8 : 24, 8, 16, 16),
                    child: Row(
                      children: [
                        if (voltar)
                          IconButton(
                            tooltip: 'Voltar',
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/galeria');
                              }
                            },
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              size: 30,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            titulo!,
                            style: voltar
                                ? Theme.of(context).textTheme.titleLarge
                                : Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        ...?actions,
                      ],
                    ),
                  ),
                Expanded(child: sheet ? Folha(child: child) : child),
                if (sessao != null && destino != null)
                  BarraInferior(sessao: sessao!, destino: destino!),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class Folha extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const Folha({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 26, 24, 20),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: .94),
          Colors.white.withValues(alpha: .78),
        ],
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      boxShadow: [
        BoxShadow(color: Miar.ink.withValues(alpha: .1), blurRadius: 40),
      ],
    ),
    child: child,
  );
}

class BarraInferior extends StatelessWidget {
  final SessaoViewModel sessao;
  final String destino;
  const BarraInferior({super.key, required this.sessao, required this.destino});
  @override
  Widget build(BuildContext context) {
    final tabs = <(String, IconData, String)>[
      ('Galeria', Icons.grid_view_rounded, '/galeria'),
      if (sessao.usuario?.podeVerRadar ?? false)
        ('Radar', Icons.location_on_outlined, '/radar'),
      ('Registrar', Icons.add_circle_outline_rounded, '/registrar'),
      if (sessao.minhasTotal > 0)
        ('Gerenciar', Icons.assignment_outlined, '/gerenciar'),
      ('Perfil', Icons.person_outline_rounded, '/perfil'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        border: Border(top: BorderSide(color: Miar.ink.withValues(alpha: .06))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: Semantics(
                selected: destino == tab.$3,
                button: true,
                label: tab.$1,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.go(tab.$3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.$2,
                          size: 24,
                          color: destino == tab.$3 ? Miar.purple : Miar.gray,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.$1,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: destino == tab.$3
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: destino == tab.$3 ? Miar.purple : Miar.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Botao extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final bool ocupado, secundario;
  final IconData? icon;
  const Botao(
    this.texto, {
    super.key,
    this.onPressed,
    this.ocupado = false,
    this.secundario = false,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onPressed == null && !ocupado ? .5 : 1,
    child: Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        gradient: secundario ? null : Miar.action,
        color: secundario ? Colors.white.withValues(alpha: .92) : null,
        border: secundario ? Border.all(color: Miar.lilac, width: 1.5) : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: secundario
            ? null
            : [
                BoxShadow(
                  color: Miar.purple.withValues(alpha: .18),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: ocupado ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Center(
              child: ocupado
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Miar.purple,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            texto,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: secundario ? Miar.purple : Colors.white,
                              shadows: secundario
                                  ? null
                                  : const [
                                      Shadow(
                                        color: Color(0x59180825),
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                            ),
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            icon,
                            size: 20,
                            color: secundario ? Miar.purple : Colors.white,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}

class Campo extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool senha, obrigatorio;
  final int linhas;
  final TextInputType? tipo;
  final IconData? icon;
  final String? Function(String?)? validar;
  const Campo({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.senha = false,
    this.obrigatorio = true,
    this.linhas = 1,
    this.tipo,
    this.icon,
    this.validar,
  });
  @override
  State<Campo> createState() => _CampoState();
}

class _CampoState extends State<Campo> {
  bool oculto = true;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Semantics(
          label: widget.label,
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.senha && oculto,
            maxLines: widget.senha ? 1 : widget.linhas,
            keyboardType: widget.tipo,
            textInputAction: widget.linhas > 1
                ? TextInputAction.newline
                : TextInputAction.next,
            autocorrect:
                !widget.senha && widget.tipo != TextInputType.emailAddress,
            enableSuggestions: !widget.senha,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.icon == null
                  ? null
                  : Icon(widget.icon, color: Miar.gray, size: 20),
              suffixIcon: widget.senha
                  ? IconButton(
                      tooltip: oculto ? 'Mostrar senha' : 'Ocultar senha',
                      onPressed: () => setState(() => oculto = !oculto),
                      icon: Icon(
                        oculto
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                    )
                  : null,
            ),
            validator: (v) =>
                widget.obrigatorio && (v == null || v.trim().isEmpty)
                ? 'Informe ${widget.label.toLowerCase()}.'
                : widget.validar?.call(v),
          ),
        ),
      ],
    ),
  );
}

class BadgeStatus extends StatelessWidget {
  final String status;
  const BadgeStatus(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (status) {
      'Encontrado' => (Miar.info, Miar.blue.withValues(alpha: .35)),
      'Emergência' => (Miar.danger, Miar.pink.withValues(alpha: .4)),
      'Aguardando Adoção' => (Miar.warning, const Color(0x73F7E2A8)),
      'Adotado' ||
      'Resgatado' => (Miar.success, Miar.mint.withValues(alpha: .35)),
      _ => (Miar.gray, Colors.white.withValues(alpha: .85)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class Cartao extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const Cartao({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .85),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Miar.ink.withValues(alpha: .05),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

class Foto extends StatelessWidget {
  final String? caminho;
  final MiarRepository repository;
  final BoxFit fit;
  final Alignment alignment;
  const Foto(
    this.caminho,
    this.repository, {
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });
  @override
  Widget build(BuildContext context) => caminho == null
      ? const ColoredBox(
          color: Color(0xCCFFFFFF),
          child: Center(
            child: Icon(Icons.pets_rounded, color: Miar.lilac, size: 40),
          ),
        )
      : Image.network(
          repository.fotoUrl(caminho!),
          fit: fit,
          alignment: alignment,
          loadingBuilder: (c, w, p) => p == null
              ? w
              : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorBuilder: (_, e, s) => const Center(
            child: Text(
              'Foto indisponível',
              style: TextStyle(color: Miar.gray, fontSize: 12),
            ),
          ),
        );
}

class Mensagem extends StatelessWidget {
  final String texto;
  final VoidCallback? tentar;
  final bool erro;
  const Mensagem(this.texto, {super.key, this.tentar, this.erro = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Cartao(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            erro ? Icons.cloud_off_outlined : Icons.pets_outlined,
            color: erro ? Miar.danger : Miar.purple,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (tentar != null)
            TextButton(
              onPressed: tentar,
              child: const Text('Tentar novamente'),
            ),
        ],
      ),
    ),
  );
}

void informar(BuildContext context, String texto) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
String formatarData(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String? validarEmail(String? s) =>
    s != null && RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s.trim())
    ? null
    : 'Informe um e-mail válido.';
