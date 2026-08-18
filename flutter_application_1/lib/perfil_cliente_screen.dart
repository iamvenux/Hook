import 'package:flutter/material.dart';
import 'main.dart' show LoginScreen;

/// Conteúdo da aba "Perfil" da home do cliente.
/// Usado dentro do Scaffold da HomeScreen (não tem AppBar/bottomNav próprios).
class PerfilClienteScreen extends StatelessWidget {
  const PerfilClienteScreen({super.key});

  static const Color azulPrincipal = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto = Color(0xFF8A8A8A);
  static const Color cinzaFundo = Color(0xFFF5F5F5);

  void _sair(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        child: const Center(
                          child: Text(
                            'C',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cliente Hook',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: pretoPrincipal,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'cliente@exemplo.com',
                              style: TextStyle(fontSize: 13, color: cinzaTexto),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildOpcaoPerfil(Icons.directions_car_outlined, 'Meus veículos'),
                _buildOpcaoPerfil(Icons.location_on_outlined, 'Endereços salvos'),
                _buildOpcaoPerfil(
                    Icons.credit_card_outlined, 'Formas de pagamento'),
                _buildOpcaoPerfil(Icons.help_outline_rounded, 'Ajuda e suporte'),
                _buildOpcaoPerfil(Icons.settings_outlined, 'Configurações'),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () => _sair(context),
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFFEF4444)),
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
                          borderRadius: BorderRadius.circular(14)),
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