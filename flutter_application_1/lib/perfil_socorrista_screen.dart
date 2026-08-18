import 'package:flutter/material.dart';
import 'main.dart' show LoginScreen;

/// Conteúdo da aba "Perfil" da home do motorista/socorrista.
/// Usado dentro do Scaffold da HomeSocorristaScreen (não tem bottomNav próprio).
class PerfilSocorristaScreen extends StatelessWidget {
  final String nome;
  final String tipoAtuacao;

  const PerfilSocorristaScreen({
    super.key,
    required this.nome,
    required this.tipoAtuacao,
  });

  static const Color azulPrincipal = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto = Color(0xFF8A8A8A);

  void _sair(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
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
                      nome.isNotEmpty ? nome[0] : '?',
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
                        style: const TextStyle(fontSize: 13, color: cinzaTexto),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildOpcaoPerfil(Icons.person_outline_rounded, 'Meus dados'),
          _buildOpcaoPerfil(Icons.directions_car_outlined, 'Veículo e documentos'),
          _buildOpcaoPerfil(
              Icons.account_balance_wallet_outlined, 'Ganhos e repasses'),
          _buildOpcaoPerfil(Icons.help_outline_rounded, 'Ajuda e suporte'),
          _buildOpcaoPerfil(Icons.settings_outlined, 'Configurações'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () => _sair(context),
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
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcaoPerfil(IconData icone, String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: azulPrincipal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, color: azulPrincipal, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: pretoPrincipal,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: cinzaTexto, size: 22),
          ],
        ),
      ),
    );
  }
}