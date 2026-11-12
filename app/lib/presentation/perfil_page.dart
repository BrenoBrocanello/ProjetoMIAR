import 'package:flutter/material.dart';

import 'auth_pages.dart';
import 'design.dart';
import 'viewmodels.dart';

class PerfilPage extends StatefulWidget {
  final SessaoViewModel sessao;
  const PerfilPage(this.sessao, {super.key});
  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  bool editando = false, ocupado = false;
  String? erro;
  final form = GlobalKey<FormState>();
  final campos = {
    for (final k in [
      'nome',
      'email',
      'telefone',
      'senha',
      ...labelsPerfil.keys,
    ])
      k: TextEditingController(),
  };
  @override
  void dispose() {
    for (final c in campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  void editar() {
    final u = widget.sessao.usuario!;
    for (final key in campos.keys) {
      campos[key]!.text = key == 'senha' ? '' : u.dados[key] as String? ?? '';
    }
    setState(() {
      editando = true;
      erro = null;
    });
  }

  Future<void> salvar() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      ocupado = true;
      erro = null;
    });
    final data = <String, dynamic>{
      for (final k in [
        'nome',
        'email',
        'telefone',
        ...camposPerfil(widget.sessao.usuario!.perfil),
      ])
        k: campos[k]!.text.trim(),
      if (campos['senha']!.text.isNotEmpty) 'senha': campos['senha']!.text,
    };
    try {
      await widget.sessao.atualizarPerfil(data);
      if (mounted) setState(() => editando = false);
    } catch (e) {
      if (mounted) setState(() => erro = e.toString());
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  Future<void> sair() async {
    setState(() {
      ocupado = true;
      erro = null;
    });
    try {
      await widget.sessao.sair();
    } catch (e) {
      if (mounted) setState(() => erro = e.toString());
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.sessao.usuario;
    if (u == null) return const SizedBox.shrink();
    return MiarLayout(
      titulo: 'Perfil',
      sessao: widget.sessao,
      destino: '/perfil',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: Miar.action,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            u.nome,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                u.perfil,
                style: const TextStyle(
                  color: Miar.purple,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Cartao(
            padding: const EdgeInsets.all(24),
            child: editando
                ? Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Campo(
                          controller: campos['nome']!,
                          label: 'Nome completo',
                        ),
                        Campo(
                          controller: campos['email']!,
                          label: 'E-mail',
                          tipo: TextInputType.emailAddress,
                          validar: validarEmail,
                        ),
                        Campo(
                          controller: campos['telefone']!,
                          label: 'Telefone (com DDD)',
                          tipo: TextInputType.phone,
                        ),
                        for (final k in camposPerfil(u.perfil))
                          Campo(
                            controller: campos[k]!,
                            label: labelsPerfil[k]!,
                            obrigatorio: false,
                          ),
                        Campo(
                          controller: campos['senha']!,
                          label: 'Senha',
                          senha: true,
                          obrigatorio: false,
                          hint: 'Preencha somente se desejar alterar',
                        ),
                        if (erro != null) Mensagem(erro!, erro: true),
                        Botao(
                          'Salvar meus dados',
                          ocupado: ocupado,
                          onPressed: salvar,
                        ),
                        TextButton(
                          onPressed: ocupado
                              ? null
                              : () => setState(() {
                                  editando = false;
                                  erro = null;
                                }),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'DADOS DA CONTA',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.6,
                          color: Miar.gray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (final k in [
                        'email',
                        'telefone',
                        ...camposPerfil(u.perfil),
                      ]) ...[
                        Text(
                          {
                            'email': 'E-mail',
                            'telefone': 'Telefone',
                            ...labelsPerfil,
                          }[k]!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (u.dados[k] as String?)?.isNotEmpty == true
                              ? u.dados[k] as String
                              : 'Não informado',
                        ),
                        const Divider(height: 28),
                      ],
                      Text(
                        'Situação da conta',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            color: Miar.success,
                            size: 8,
                          ),
                          const SizedBox(width: 8),
                          Text(u.dados['ativo'] == true ? 'Ativa' : 'Inativa'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Botao(
                        'Atualizar meus dados',
                        onPressed: ocupado ? null : editar,
                      ),
                      const SizedBox(height: 16),
                      Botao(
                        'Sair da conta',
                        secundario: true,
                        ocupado: ocupado,
                        onPressed: sair,
                        icon: Icons.logout_rounded,
                      ),
                      if (erro != null) Mensagem(erro!, erro: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
