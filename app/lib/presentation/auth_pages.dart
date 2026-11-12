import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/entidades.dart';
import 'design.dart';
import 'viewmodels.dart';

class LoginPage extends StatefulWidget {
  final SessaoViewModel sessao;
  const LoginPage(this.sessao, {super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(), senha = TextEditingController();
  final form = GlobalKey<FormState>();
  bool ocupado = false;
  String? erro;
  @override
  void dispose() {
    email.dispose();
    senha.dispose();
    super.dispose();
  }

  Future<void> entrar() async {
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      ocupado = true;
      erro = null;
    });
    try {
      await widget.sessao.entrar(email.text, senha.text);
    } catch (e) {
      if (mounted) setState(() => erro = e.toString());
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => MiarLayout(
    child: LayoutBuilder(
      builder: (context, size) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.maxHeight),
          child: Column(
            children: [
              const SizedBox(height: 18),
              Image.asset(
                'assets/img/miar-wordmark.png',
                height: 62,
                semanticLabel: 'MIAR',
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'MAPEAMENTO E IDENTIFICAÇÃO DE ANIMAIS DE RISCO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.6,
                    color: Miar.gray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: size.maxHeight > 800 ? 225 : 160,
                width: double.infinity,
                child: Image.asset(
                  'assets/img/hero-cao-gato.jpg',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -.35),
                  semanticLabel: 'Cão e gato',
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -25),
                child: Folha(
                  child: Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Bem-vindo de volta',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Entre na sua conta para continuar ajudando animais em situação de risco.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Miar.gray),
                        ),
                        const SizedBox(height: 24),
                        if (erro ?? widget.sessao.erroInicial
                            case final String message)
                          Mensagem(message, erro: true),
                        Campo(
                          controller: email,
                          label: 'E-mail',
                          hint: 'seu@email.com',
                          tipo: TextInputType.emailAddress,
                          icon: Icons.mail_outline_rounded,
                          validar: validarEmail,
                        ),
                        Campo(
                          controller: senha,
                          label: 'Senha',
                          hint: 'Sua senha',
                          senha: true,
                          icon: Icons.lock_outline_rounded,
                        ),
                        const SizedBox(height: 4),
                        Botao(
                          'Entrar',
                          onPressed: entrar,
                          ocupado: ocupado,
                          icon: Icons.arrow_forward_rounded,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Ainda não tem conta?',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Botao(
                          'Criar conta',
                          secundario: true,
                          onPressed: ocupado
                              ? null
                              : () => context.push('/cadastro'),
                          icon: Icons.person_add_alt_1_outlined,
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
    ),
  );
}

class CadastroPage extends StatefulWidget {
  final SessaoViewModel sessao;
  const CadastroPage(this.sessao, {super.key});
  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final form = GlobalKey<FormState>();
  final campos = {
    for (final k in ['nome', 'email', 'telefone', 'senha', 'documento'])
      k: TextEditingController(),
  };
  String perfil = perfis.first;
  bool ocupado = false;
  String? erro;
  @override
  void dispose() {
    for (final c in campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> salvar() async {
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      ocupado = true;
      erro = null;
    });
    final Json data = {'tipo_usuario': perfil};
    final keys = [
      'nome',
      'email',
      'telefone',
      'senha',
      ...camposPerfil(perfil),
    ];
    for (final key in keys) {
      final value = key == 'senha'
          ? campos[key]!.text
          : campos[key]!.text.trim();
      if (value.isNotEmpty) data[key] = value;
    }
    try {
      await widget.sessao.repository.cadastrar(data);
      if (mounted) {
        informar(context, 'Cadastro realizado. Entre com seu e-mail e senha.');
        context.pop();
      }
    } catch (e) {
      if (mounted) setState(() => erro = e.toString());
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => MiarLayout(
    titulo: 'Criar conta',
    voltar: true,
    sheet: true,
    child: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Preencha seus dados para participar da rede de proteção aos animais.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Miar.gray),
            ),
            const SizedBox(height: 24),
            Text(
              'Perfil de usuário',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < perfis.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      child: Semantics(
                        selected: perfil == perfis[i],
                        child: InkWell(
                          onTap: ocupado
                              ? null
                              : () => setState(() => perfil = perfis[i]),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: perfil == perfis[i]
                                    ? Miar.purple
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  [
                                    Icons.person_outline,
                                    Icons.favorite_border,
                                    Icons.home_work_outlined,
                                  ][i],
                                  color: perfil == perfis[i]
                                      ? Miar.purple
                                      : Miar.gray,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  ['Cidadão', 'Protetor', 'ONG'][i],
                                  style: TextStyle(
                                    color: perfil == perfis[i]
                                        ? Miar.purple
                                        : Miar.ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Campo(
              controller: campos['nome']!,
              label: 'Nome completo',
              icon: Icons.person_outline,
            ),
            Campo(
              controller: campos['email']!,
              label: 'E-mail',
              tipo: TextInputType.emailAddress,
              icon: Icons.mail_outline,
              validar: validarEmail,
            ),
            Campo(
              controller: campos['telefone']!,
              label: 'Telefone (com DDD)',
              tipo: TextInputType.phone,
              hint: '(11) 98765-4321',
              icon: Icons.phone_outlined,
            ),
            ...camposPerfil(perfil).map(
              (k) => Campo(
                key: ValueKey('$perfil-$k'),
                controller: campos[k]!,
                label: labelsPerfil[k]!,
                obrigatorio: false,
              ),
            ),
            Campo(
              controller: campos['senha']!,
              label: 'Senha',
              senha: true,
              icon: Icons.lock_outline,
            ),
            if (erro != null) Mensagem(erro!, erro: true),
            Botao(
              'Criar conta',
              onPressed: salvar,
              ocupado: ocupado,
              icon: Icons.arrow_forward,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

List<String> camposPerfil(String perfil) => ['documento'];
const labelsPerfil = {'documento': 'Documento (CPF/CNPJ)'};
