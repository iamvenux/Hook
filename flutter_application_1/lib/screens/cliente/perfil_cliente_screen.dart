import 'package:flutter/material.dart';

import 'package:flutter_application_1/controllers/auth_controller.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';
import 'package:flutter_application_1/screens/cliente/enderecos_salvos_screen.dart';
import 'package:flutter_application_1/screens/perfil/ajuda_suporte_screen.dart';
import 'package:flutter_application_1/screens/perfil/alterar_senha_screen.dart';
import 'package:flutter_application_1/screens/perfil/configuracoes_screen.dart';
import 'package:flutter_application_1/screens/perfil/forma_pagamento_screen.dart';
import 'package:flutter_application_1/screens/perfil/meus_dados_screen.dart';
import 'package:flutter_application_1/widgets/opcao_perfil.dart';
import 'package:flutter_application_1/widgets/telefone_input_formatter.dart';

/// Conteúdo da aba "Perfil" da home do cliente.
/// Usado dentro do Scaffold da HomeScreen (não tem AppBar/bottomNav próprios).
class PerfilClienteScreen extends StatefulWidget {
  /// Chamado quando o usuário toca em "Meus veículos";
  /// a home troca para a aba de veículos.
  final VoidCallback? onAbrirVeiculos;

  const PerfilClienteScreen({
    super.key,
    this.onAbrirVeiculos,
  });

  @override
  State<PerfilClienteScreen> createState() => _PerfilClienteScreenState();
}

class _PerfilClienteScreenState extends State<PerfilClienteScreen> {
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto = Color(0xFF8A8A8A);
  static const Color cinzaFundo = Color(0xFFF5F5F5);

  final AuthController _auth = AuthController.instance;

  Future<void> _abrirMeusDados() async {
    final alterou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const MeusDadosScreen()),
    );

    if (alterou == true && mounted) {
      // Os getters do controller já têm os dados novos.
      setState(() {});
    }
  }

  void _abrirAlterarSenha() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AlterarSenhaScreen()),
    );
  }

  void _abrirEnderecos() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EnderecosSalvosScreen()),
    );
  }

  Future<void> _abrirFormaPagamento() async {
    final alterou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const FormaPagamentoScreen()),
    );

    if (alterou == true && mounted) {
      setState(() {});
    }
  }

  void _abrirAjuda() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AjudaSuporteScreen()),
    );
  }

  void _abrirConfiguracoes() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()),
    );
  }

  void _sair() {
    _auth.logout();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome = _auth.nomeUsuario?.trim() ?? '';
    final email = _auth.emailUsuario ?? '';
    final telefone = TelefoneInputFormatter.formatar(
      _auth.telefoneUsuario ?? '',
    );

    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 32, 24, 0),
          child: Text(
            'Meu Perfil',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: pretoPrincipal,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Gerencie suas informações e preferências',
            style: TextStyle(fontSize: 14, color: cinzaTexto),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cinzaFundo,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2E8FF7), Color(0xFF1565D8)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            inicial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome.isNotEmpty ? nome : 'Cliente',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: pretoPrincipal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 13,
                                color: cinzaTexto,
                              ),
                            ),
                            if (telefone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                telefone,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: cinzaTexto,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OpcaoPerfil(
                  icone: Icons.person_outline_rounded,
                  titulo: 'Meus dados',
                  onTap: _abrirMeusDados,
                ),
                OpcaoPerfil(
                  icone: Icons.directions_car_outlined,
                  titulo: 'Meus veículos',
                  onTap: () => widget.onAbrirVeiculos?.call(),
                ),
                OpcaoPerfil(
                  icone: Icons.location_on_outlined,
                  titulo: 'Endereços salvos',
                  onTap: _abrirEnderecos,
                ),
                OpcaoPerfil(
                  icone: Icons.credit_card_outlined,
                  titulo: 'Forma de pagamento',
                  onTap: _abrirFormaPagamento,
                ),
                OpcaoPerfil(
                  icone: Icons.lock_outline_rounded,
                  titulo: 'Alterar senha',
                  onTap: _abrirAlterarSenha,
                ),
                OpcaoPerfil(
                  icone: Icons.help_outline_rounded,
                  titulo: 'Ajuda e suporte',
                  onTap: _abrirAjuda,
                ),
                OpcaoPerfil(
                  icone: Icons.settings_outlined,
                  titulo: 'Configurações',
                  onTap: _abrirConfiguracoes,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _sair,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                    ),
                    label: const Text(
                      'Sair',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
