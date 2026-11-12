import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/controllers/auth_controller.dart';
import 'package:flutter_application_1/models/api_exception.dart';
import 'package:flutter_application_1/widgets/telefone_input_formatter.dart';

/// Tela para o usuário logado ver e editar os próprios dados.
///
/// Serve para cliente e motorista: para motorista mostra também
/// placa e tipo do guincho. Fecha devolvendo `true` quando salvou.
class MeusDadosScreen extends StatefulWidget {
  const MeusDadosScreen({super.key});

  @override
  State<MeusDadosScreen> createState() => _MeusDadosScreenState();
}

class _MeusDadosScreenState extends State<MeusDadosScreen> {
  static const Color azulPrincipal = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto = Color(0xFF8A8A8A);
  static const Color cinzaFundo = Color(0xFFF5F5F5);

  final AuthController _auth = AuthController.instance;

  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _placaController = TextEditingController();

  String _email = '';
  String _tipoGuincho = 'Leve';

  bool _ehMotorista = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();

    _ehMotorista = _auth.ehMotorista;
    _email = _auth.emailUsuario ?? '';

    _nomeController.text = _auth.nomeUsuario ?? '';
    _telefoneController.text =
        TelefoneInputFormatter.formatar(_auth.telefoneUsuario ?? '');
    _placaController.text = _auth.placaGuincho ?? '';
    _tipoGuincho = _auth.tipoGuincho == 'Pesado' ? 'Pesado' : 'Leve';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _placaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
    });

    try {
      await _auth.atualizarPerfil(
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.replaceAll(RegExp(r'\D'), ''),
        placaGuincho:
            _ehMotorista ? _placaController.text.trim().toUpperCase() : null,
        tipoGuincho: _ehMotorista ? _tipoGuincho : null,
      );

      if (!mounted) return;

      _mostrarMensagem('Dados atualizados com sucesso.');

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
          'Meus dados',
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
                    _buildLabel('Nome'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nomeController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 15,
                        color: pretoPrincipal,
                      ),
                      decoration: _decoracao(
                        hint: 'Seu nome completo',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Informe seu nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('E-mail'),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _email,
                      enabled: false,
                      style: const TextStyle(
                        fontSize: 15,
                        color: cinzaTexto,
                      ),
                      decoration: _decoracao(
                        hint: '',
                        icon: Icons.mail_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'O e-mail é usado para entrar e não pode ser alterado.',
                      style: TextStyle(fontSize: 12, color: cinzaTexto),
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Celular'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _telefoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TelefoneInputFormatter(),
                      ],
                      style: const TextStyle(
                        fontSize: 15,
                        color: pretoPrincipal,
                      ),
                      decoration: _decoracao(
                        hint: '(11) 99999-9999',
                        icon: Icons.phone_outlined,
                      ),
                      validator: (valor) {
                        final numeros =
                            (valor ?? '').replaceAll(RegExp(r'\D'), '');
                        if (numeros.length != 11) {
                          return 'Informe um celular válido com DDD';
                        }
                        return null;
                      },
                    ),
                    if (_ehMotorista) ...[
                      const SizedBox(height: 20),
                      _buildLabel('Placa do guincho'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _placaController,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp('[A-Za-z0-9]'),
                          ),
                          LengthLimitingTextInputFormatter(7),
                        ],
                        style: const TextStyle(
                          fontSize: 15,
                          color: pretoPrincipal,
                          letterSpacing: 1.5,
                        ),
                        decoration: _decoracao(
                          hint: 'ABC1D23',
                          icon: Icons.local_shipping_outlined,
                        ),
                        validator: (valor) {
                          if ((valor ?? '').trim().length != 7) {
                            return 'A placa deve ter 7 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Tipo de guincho'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTipoGuincho(
                              valor: 'Leve',
                              titulo: 'Guincho Leve',
                              subtitulo: 'Até 3.5 toneladas',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTipoGuincho(
                              valor: 'Pesado',
                              titulo: 'Guincho Pesado',
                              subtitulo: 'Caminhões e ônibus',
                            ),
                          ),
                        ],
                      ),
                    ],
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
                          'Salvar alterações',
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

  InputDecoration _decoracao({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: cinzaTexto),
      prefixIcon: Icon(icon, color: cinzaTexto, size: 20),
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
    );
  }

  Widget _buildTipoGuincho({
    required String valor,
    required String titulo,
    required String subtitulo,
  }) {
    final selecionado = _tipoGuincho == valor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoGuincho = valor;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selecionado ? azulPrincipal : cinzaFundo,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selecionado ? azulPrincipal : const Color(0xFFEEEEEE),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selecionado ? Colors.white : pretoPrincipal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitulo,
              style: TextStyle(
                fontSize: 12,
                color: selecionado
                    ? Colors.white.withValues(alpha: 0.85)
                    : cinzaTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
