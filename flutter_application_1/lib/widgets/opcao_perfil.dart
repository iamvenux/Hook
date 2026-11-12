import 'package:flutter/material.dart';

/// Linha de opção usada nas telas de perfil (ícone, título e seta).
class OpcaoPerfil extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final VoidCallback onTap;

  static const Color azulPrincipal = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto = Color(0xFF8A8A8A);

  const OpcaoPerfil({
    super.key,
    required this.icone,
    required this.titulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: azulPrincipal.withValues(alpha: 0.1),
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
                const Icon(
                  Icons.chevron_right_rounded,
                  color: cinzaTexto,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
