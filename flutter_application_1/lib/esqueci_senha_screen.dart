import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  static const Color azulPrincipal  = Color(0xFF1A7EF5);
  static const Color cinzaTexto     = Color(0xFF8A8A8A);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);

  // 0 = digitar email, 1 = digitar código, 2 = nova senha
  int _etapa = 0;

  final _emailController     = TextEditingController();
  final _novaSenhaController  = TextEditingController();
  final _confirmarController  = TextEditingController();
  final List<TextEditingController> _codigoControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codigoFocus =
      List.generate(6, (_) => FocusNode());

  bool _novaSenhaVisivel     = false;
  bool _confirmarSenhaVisivel = false;
  bool _carregando           = false;

  @override
  void dispose() {
    _emailController.dispose();
    _novaSenhaController.dispose();
    _confirmarController.dispose();
    for (final c in _codigoControllers) c.dispose();
    for (final f in _codigoFocus) f.dispose();
    super.dispose();
  }

  Future<void> _avancar() async {
    setState(() => _carregando = true);
    await Future.delayed(const Duration(seconds: 1)); // TODO: API
    setState(() {
      _carregando = false;
      if (_etapa < 2) _etapa++;
    });
    if (_etapa == 1) {
      Future.delayed(
          const Duration(milliseconds: 100), () => _codigoFocus[0].requestFocus());
    }
  }

  Future<void> _redefinirSenha() async {
    setState(() => _carregando = true);
    await Future.delayed(const Duration(seconds: 1)); // TODO: API
    setState(() => _carregando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida com sucesso!')),
      );
      Navigator.pop(context);
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
          onTap: () {
            if (_etapa > 0) {
              setState(() => _etapa--);
            } else {
              Navigator.pop(context);
            }
          },
          child: const Icon(Icons.arrow_back, color: pretoPrincipal),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Indicador de etapas
              Row(
                children: List.generate(3, (i) {
                  final ativo     = i == _etapa;
                  final concluido = i < _etapa;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: concluido || ativo
                            ? azulPrincipal
                            : const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // Título e subtítulo dinâmicos
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Column(
                  key: ValueKey(_etapa),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _etapa == 0
                          ? 'Esqueceu a senha?'
                          : _etapa == 1
                              ? 'Verifique seu email'
                              : 'Nova senha',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: pretoPrincipal,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _etapa == 0
                          ? 'Informe seu email e enviaremos um código de verificação.'
                          : _etapa == 1
                              ? 'Enviamos um código de 6 dígitos para ${_emailController.text}.'
                              : 'Escolha uma nova senha segura para sua conta.',
                      style: const TextStyle(fontSize: 15, color: cinzaTexto),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ── Etapa 0: Email ──────────────────────
              if (_etapa == 0) ...[
                _buildLabel('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style:
                      const TextStyle(fontSize: 15, color: pretoPrincipal),
                  decoration: _inputDecoration(
                    hint: 'nome@exemplo.com',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 32),
                _buildBotao('Enviar código', _avancar),
              ],

              // ── Etapa 1: Código ─────────────────────
              if (_etapa == 1) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    return SizedBox(
                      width: 46,
                      height: 56,
                      child: TextField(
                        controller: _codigoControllers[i],
                        focusNode: _codigoFocus[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: pretoPrincipal),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: azulPrincipal, width: 1.8),
                          ),
                        ),
                        onChanged: (v) {
                          if (v.isNotEmpty && i < 5) {
                            _codigoFocus[i + 1].requestFocus();
                          } else if (v.isEmpty && i > 0) {
                            _codigoFocus[i - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () {}, // TODO: reenviar código
                    child: const Text(
                      'Reenviar código',
                      style: TextStyle(
                          fontSize: 14,
                          color: azulPrincipal,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildBotao('Verificar código', _avancar),
              ],

              // ── Etapa 2: Nova senha ─────────────────
              if (_etapa == 2) ...[
                _buildLabel('Nova senha'),
                const SizedBox(height: 8),
                _buildInputSenha(
                  controller: _novaSenhaController,
                  visivel: _novaSenhaVisivel,
                  onToggle: () =>
                      setState(() => _novaSenhaVisivel = !_novaSenhaVisivel),
                ),
                const SizedBox(height: 20),
                _buildLabel('Confirmar nova senha'),
                const SizedBox(height: 8),
                _buildInputSenha(
                  controller: _confirmarController,
                  visivel: _confirmarSenhaVisivel,
                  onToggle: () => setState(
                      () => _confirmarSenhaVisivel = !_confirmarSenhaVisivel),
                ),
                const SizedBox(height: 32),
                _buildBotao('Redefinir senha', _redefinirSenha),
              ],

              const SizedBox(height: 40),
            ],
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

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: cinzaTexto, fontSize: 15),
      prefixIcon: Icon(icon, color: cinzaTexto, size: 20),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: azulPrincipal, width: 1.8),
      ),
    );
  }

  Widget _buildInputSenha({
    required TextEditingController controller,
    required bool visivel,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visivel,
      style: const TextStyle(fontSize: 15, color: pretoPrincipal),
      decoration: InputDecoration(
        hintText: '••••••••',
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
          borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: azulPrincipal, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildBotao(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _carregando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: azulPrincipal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: azulPrincipal.withOpacity(0.6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _carregando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}