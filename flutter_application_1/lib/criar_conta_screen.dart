import 'package:flutter/material.dart';
import 'home.dart';

class CriarContaScreen extends StatefulWidget {
  const CriarContaScreen({super.key});

  @override
  State<CriarContaScreen> createState() => _CriarContaScreenState();
}

class _CriarContaScreenState extends State<CriarContaScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _nomeController  = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController    = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _senhaVisivel         = false;
  bool _confirmarSenhaVisivel = false;
  bool _carregando           = false;

  static const Color azulPrincipal  = Color(0xFF1A7EF5);
  static const Color cinzaTexto     = Color(0xFF8A8A8A);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaFundo     = Color(0xFFF5F5F5);

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _criarConta() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    await Future.delayed(const Duration(seconds: 2));

    setState(() => _carregando = false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: pretoPrincipal),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Título
                const Text(
                  'Criar conta',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: pretoPrincipal,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Preencha os dados para começar',
                  style: TextStyle(fontSize: 15, color: cinzaTexto),
                ),

                const SizedBox(height: 32),

                // Nome completo
                _buildLabel('Nome completo'),
                const SizedBox(height: 8),
                _buildInput(
                  controller: _nomeController,
                  hint: 'Seu nome',
                  icon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe seu nome' : null,
                ),

                const SizedBox(height: 20),

                // Email
                _buildLabel('Email'),
                const SizedBox(height: 8),
                _buildInput(
                  controller: _emailController,
                  hint: 'nome@exemplo.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe seu email';
                    if (!v.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Telefone
                _buildLabel('Telefone'),
                const SizedBox(height: 8),
                _buildInput(
                  controller: _telefoneController,
                  hint: '(11) 99999-9999',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe seu telefone' : null,
                ),

                const SizedBox(height: 20),

                // Senha
                _buildLabel('Senha'),
                const SizedBox(height: 8),
                _buildInputSenha(
                  controller: _senhaController,
                  hint: '••••••••',
                  visivel: _senhaVisivel,
                  onToggle: () =>
                      setState(() => _senhaVisivel = !_senhaVisivel),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe sua senha';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Confirmar senha
                _buildLabel('Confirmar senha'),
                const SizedBox(height: 8),
                _buildInputSenha(
                  controller: _confirmarSenhaController,
                  hint: '••••••••',
                  visivel: _confirmarSenhaVisivel,
                  onToggle: () => setState(
                      () => _confirmarSenhaVisivel = !_confirmarSenhaVisivel),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirme sua senha';
                    if (v != _senhaController.text) return 'As senhas não coincidem';
                    return null;
                  },
                ),

                const SizedBox(height: 36),

                // Botão criar conta
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _criarConta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulPrincipal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: azulPrincipal.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _carregando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Criar conta',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Já tem conta
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Já tem cadastro? ',
                        style: TextStyle(fontSize: 14, color: cinzaTexto)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Entrar',
                        style: TextStyle(
                            fontSize: 14,
                            color: azulPrincipal,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String texto) => Text(
        texto,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: pretoPrincipal),
      );

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: pretoPrincipal),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: cinzaTexto, fontSize: 15),
        prefixIcon: Icon(icon, color: cinzaTexto, size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: azulPrincipal, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildInputSenha({
    required TextEditingController controller,
    required String hint,
    required bool visivel,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visivel,
      style: const TextStyle(fontSize: 15, color: pretoPrincipal),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: cinzaTexto, fontSize: 18),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(
            visivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: cinzaTexto,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: azulPrincipal, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.8),
        ),
      ),
    );
  }
}