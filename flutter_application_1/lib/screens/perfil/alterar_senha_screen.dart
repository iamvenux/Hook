import 'package:flutter/material.dart';

import 'package:flutter_application_1/controllers/auth_controller.dart';
import 'package:flutter_application_1/models/api_exception.dart';

/// Troca de senha do usuário logado (pede a senha atual).
/// Fecha devolvendo `true` quando a senha foi alterada.
class AlterarSenhaScreen extends StatefulWidget {
  const AlterarSenhaScreen({super.key});

  @override
  State<AlterarSenhaScreen> createState() => _AlterarSenhaScreenState();
}

class _AlterarSenhaScreenState extends State<AlterarSenhaScreen> {
  static const Color azulPrincipal = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto = Color(0xFF8A8A8A);
  static const Color cinzaFundo = Color(0xFFF5F5F5);

  final _formKey = GlobalKey<FormState>();

  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _senhaAtualVisivel = false;
  bool _novaSenhaVisivel = false;
  bool _confirmarSenhaVisivel = false;

  bool _salvando = false;

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
    });

    try {
      await AuthController.instance.alterarSenha(
        senhaAtual: _senhaAtualController.text,
        novaSenha: _novaSenhaController.text,
      );

      if (!mounted) return;

      _mostrarMensagem('Senha alterada com sucesso.');

      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _salvando = false;
      });

      _mostrarMensagem(e.mensagem);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _salvando = false;
      });

      _mostrarMensagem('Não foi possível conectar ao servidor.');
    }
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
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
          'Alterar senha',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: pretoPrincipal,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Por segurança, confirme sua senha atual antes de '
                      'escolher uma nova.',
                      style: TextStyle(fontSize: 14, color: cinzaTexto),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Senha atual'),
                    const SizedBox(height: 8),
                    _buildCampoSenha(
                      controller: _senhaAtualController,
                      visivel: _senhaAtualVisivel,
                      onToggle: () => setState(() {
                        _senhaAtualVisivel = !_senhaAtualVisivel;
                      }),
                      validator: (valor) {
                        if (valor == null || valor.isEmpty) {
                          return 'Informe sua senha atual';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Nova senha'),
                    const SizedBox(height: 8),
                    _buildCampoSenha(
                      controller: _novaSenhaController,
                      visivel: _novaSenhaVisivel,
                      onToggle: () => setState(() {
                        _novaSenhaVisivel = !_novaSenhaVisivel;
                      }),
                      validator: (valor) {
                        if (valor == null || valor.length < 6) {
                          return 'A nova senha deve ter pelo menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Confirmar nova senha'),
                    const SizedBox(height: 8),
                    _buildCampoSenha(
                      controller: _confirmarSenhaController,
                      visivel: _confirmarSenhaVisivel,
                      onToggle: () => setState(() {
                        _confirmarSenhaVisivel = !_confirmarSenhaVisivel;
                      }),
                      validator: (valor) {
                        if (valor != _novaSenhaController.text) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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
                          'Alterar senha',
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
      ),
    );
  }

  Widget _buildLabel(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: pretoPrincipal,
      ),
    );
  }

  Widget _buildCampoSenha({
    required TextEditingController controller,
    required bool visivel,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visivel,
      style: const TextStyle(fontSize: 15, color: pretoPrincipal),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: const TextStyle(color: cinzaTexto, fontSize: 18),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: cinzaTexto,
          size: 20,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            visivel
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: cinzaTexto,
          ),
        ),
        filled: true,
        fillColor: cinzaFundo,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }
}
