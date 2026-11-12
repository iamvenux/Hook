import 'package:flutter/material.dart';

import 'package:flutter_application_1/controllers/auth_controller.dart';
import 'package:flutter_application_1/models/api_exception.dart';

/// Forma de pagamento padrão do cliente (já vem marcada ao pedir
/// um serviço; ainda dá para trocar na hora).
class FormaPagamentoScreen extends StatefulWidget {
  const FormaPagamentoScreen({super.key});

  @override
  State<FormaPagamentoScreen> createState() => _FormaPagamentoScreenState();
}

class _FormaPagamentoScreenState extends State<FormaPagamentoScreen> {
  static const Color azulPrincipal = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto = Color(0xFF8A8A8A);
  static const Color cinzaFundo = Color(0xFFF5F5F5);

  static const Map<String, String> _formas = {
    'Pix': 'Pagamento instantâneo',
    'Dinheiro': 'Pagamento em espécie',
  };

  late String _selecionada;

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _selecionada = AuthController.instance.formaPagamentoPadrao;
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
    });

    try {
      await AuthController.instance.atualizarFormaPagamento(_selecionada);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Forma de pagamento padrão salva.')),
      );

      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _salvando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem)),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _salvando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível conectar ao servidor.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: pretoPrincipal),
        ),
        title: const Text(
          'Forma de pagamento',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: pretoPrincipal,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Escolha a forma que vai aparecer selecionada sempre que '
                  'você pedir um serviço. Dá para trocar na hora do pedido.',
                  style: TextStyle(fontSize: 14, color: cinzaTexto),
                ),
                const SizedBox(height: 20),
                ..._formas.entries.map(
                  (entrada) => _buildOpcao(
                    valor: entrada.key,
                    descricao: entrada.value,
                    icone: entrada.key == 'Pix'
                        ? Icons.qr_code_2_rounded
                        : Icons.payments_outlined,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulPrincipal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      azulPrincipal.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _salvando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Salvar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcao({
    required String valor,
    required String descricao,
    required IconData icone,
  }) {
    final selecionado = _selecionada == valor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selecionada = valor;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selecionado
                ? azulPrincipal.withValues(alpha: 0.08)
                : cinzaFundo,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selecionado ? azulPrincipal : const Color(0xFFEEEEEE),
              width: selecionado ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selecionado ? azulPrincipal : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icone,
                  color: selecionado ? Colors.white : azulPrincipal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valor,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: pretoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descricao,
                      style: const TextStyle(fontSize: 13, color: cinzaTexto),
                    ),
                  ],
                ),
              ),
              Icon(
                selecionado
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selecionado ? azulPrincipal : cinzaTexto,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
