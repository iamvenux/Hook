import 'package:flutter/material.dart';

import 'package:flutter_application_1/controllers/auth_controller.dart';
import 'package:flutter_application_1/controllers/socorrista_controller.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';
import 'package:flutter_application_1/screens/perfil/ajuda_suporte_screen.dart';
import 'package:flutter_application_1/screens/perfil/alterar_senha_screen.dart';
import 'package:flutter_application_1/screens/perfil/configuracoes_screen.dart';
import 'package:flutter_application_1/screens/perfil/meus_dados_screen.dart';
import 'package:flutter_application_1/screens/socorrista/ganhos_screen.dart';
import 'package:flutter_application_1/widgets/opcao_perfil.dart';
import 'package:flutter_application_1/widgets/telefone_input_formatter.dart';

/// Conteúdo da aba "Perfil" da home do motorista/socorrista.
/// Usado dentro do Scaffold da HomeSocorristaScreen (não tem bottomNav próprio).
class PerfilSocorristaScreen extends StatefulWidget {
  /// Chamado depois que o socorrista salva "Meus dados", para a home
  /// atualizar o nome no cabeçalho.
  final VoidCallback? onPerfilAtualizado;

  const PerfilSocorristaScreen({
    super.key,
    this.onPerfilAtualizado,
  });

  @override
  State<PerfilSocorristaScreen> createState() =>
      _PerfilSocorristaScreenState();
}

class _PerfilSocorristaScreenState extends State<PerfilSocorristaScreen> {
  static const Color azulPrincipal = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto = Color(0xFF8A8A8A);
  static const Color cinzaFundo = Color(0xFFF5F5F5);

  final AuthController _auth = AuthController.instance;
  final SocorristaController _socorrista = SocorristaController.instance;

  Future<void> _abrirMeusDados() async {
    final alterou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const MeusDadosScreen()),
    );

    if (alterou == true && mounted) {
      setState(() {});
      widget.onPerfilAtualizado?.call();
    }
  }

  void _abrirAlterarSenha() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AlterarSenhaScreen()),
    );
  }

  void _abrirGanhos() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GanhosScreen()),
    );
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
    final nome = _socorrista.nomeSocorrista.trim();
    final tipoAtuacao = _socorrista.tipoAtuacao;
    final email = _auth.emailUsuario ?? '';
    final telefone = TelefoneInputFormatter.formatar(
      _auth.telefoneUsuario ?? '',
    );
    final placa = _auth.placaGuincho ?? '';

    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E8FF7), Color(0xFF1565D8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                            nome,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: pretoPrincipal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tipoAtuacao,
                            style: const TextStyle(
                              fontSize: 13,
                              color: cinzaTexto,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfo(Icons.mail_outline_rounded, email),
                if (telefone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfo(Icons.phone_outlined, telefone),
                ],
                if (placa.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfo(Icons.local_shipping_outlined, 'Placa $placa'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          OpcaoPerfil(
            icone: Icons.person_outline_rounded,
            titulo: 'Meus dados',
            onTap: _abrirMeusDados,
          ),
          OpcaoPerfil(
            icone: Icons.account_balance_wallet_outlined,
            titulo: 'Ganhos e repasses',
            onTap: _abrirGanhos,
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _sair,
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
              label: const Text(
                'Sair',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(IconData icone, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cinzaFundo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icone, color: azulPrincipal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13, color: pretoPrincipal),
            ),
          ),
        ],
      ),
    );
  }
}
