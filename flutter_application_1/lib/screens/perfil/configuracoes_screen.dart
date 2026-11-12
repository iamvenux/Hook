import 'package:flutter/material.dart';

import 'package:flutter_application_1/controllers/auth_controller.dart';
import 'package:flutter_application_1/models/api_exception.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';

/// Configurações da conta: informações do app e exclusão da conta.
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  static const Color azulPrincipal = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto = Color(0xFF8A8A8A);
  static const Color cinzaFundo = Color(0xFFF5F5F5);
  static const Color vermelho = Color(0xFFEF4444);

  /// Mesma versão do pubspec.yaml.
  static const String versaoApp = '1.0.0';

  bool _excluindo = false;

  // ============================================================
  // EXCLUIR CONTA
  // ============================================================

  Future<void> _confirmarExclusao() async {
    final senhaController = TextEditingController();
    var senhaVisivel = false;

    final senha = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Excluir conta?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: pretoPrincipal,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Isso apaga seus dados pessoais, veículos e endereços. '
                    'Esta ação não pode ser desfeita.\n\n'
                    'Digite sua senha para confirmar:',
                    style: TextStyle(fontSize: 14, color: cinzaTexto),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: senhaController,
                    obscureText: !senhaVisivel,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Senha',
                      filled: true,
                      fillColor: cinzaFundo,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          senhaVisivel
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: cinzaTexto,
                        ),
                        onPressed: () => setStateDialog(() {
                          senhaVisivel = !senhaVisivel;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: cinzaTexto),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (senhaController.text.isEmpty) return;
                    Navigator.of(dialogContext).pop(senhaController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vermelho,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Excluir conta'),
                ),
              ],
            );
          },
        );
      },
    );

    if (senha == null || senha.isEmpty || !mounted) return;

    setState(() {
      _excluindo = true;
    });

    try {
      await AuthController.instance.excluirConta(senha: senha);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta excluída.')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _excluindo = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem)),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _excluindo = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível conectar ao servidor.')),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.instance;

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
          'Configurações',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: pretoPrincipal,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'CONTA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cinzaTexto,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildLinha(
            icone: Icons.mail_outline_rounded,
            titulo: 'E-mail de acesso',
            valor: auth.emailUsuario ?? '',
          ),
          _buildLinha(
            icone: Icons.badge_outlined,
            titulo: 'Tipo de conta',
            valor: auth.ehMotorista ? 'Socorrista' : 'Cliente',
          ),
          const SizedBox(height: 24),
          const Text(
            'SOBRE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cinzaTexto,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildLinha(
            icone: Icons.info_outline_rounded,
            titulo: 'Versão do app',
            valor: versaoApp,
          ),
          _buildLinha(
            icone: Icons.school_outlined,
            titulo: 'Hook',
            valor: 'Socorro e guincho veicular. Projeto acadêmico - Fatec.',
          ),
          const SizedBox(height: 24),
          const Text(
            'ZONA DE PERIGO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: vermelho,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _excluindo ? null : _confirmarExclusao,
              icon: _excluindo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: vermelho,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.delete_forever_outlined, color: vermelho),
              label: const Text(
                'Excluir minha conta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: vermelho,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: vermelho),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seus dados pessoais são removidos e o acesso é encerrado. '
            'O histórico de serviços fica anônimo.',
            style: TextStyle(fontSize: 12, color: cinzaTexto),
          ),
        ],
      ),
    );
  }

  Widget _buildLinha({
    required IconData icone,
    required String titulo,
    required String valor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cinzaFundo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: azulPrincipal, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 12, color: cinzaTexto),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: pretoPrincipal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
