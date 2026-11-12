import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Modal de confirmação de conclusão
// ─────────────────────────────────────────────
class ModalConcluir extends StatelessWidget {
  final String nomeUsuario;
  final VoidCallback onConfirmar;

  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto     = Color(0xFF8A8A8A);

  const ModalConcluir({
    super.key,
    required this.nomeUsuario,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Finalizar atendimento?',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: pretoPrincipal)),
          const SizedBox(height: 6),
          Text(
            'Confirme apenas se o serviço prestado a $nomeUsuario foi concluído.',
            style: const TextStyle(fontSize: 14, color: cinzaTexto),
          ),

          const SizedBox(height: 24),

          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cinzaTexto,
                  side: const BorderSide(color: Color(0xFFDDDDDD)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Voltar',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onConfirmar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Confirmar conclusão',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
