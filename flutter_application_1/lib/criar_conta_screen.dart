import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';
import 'confirmar_email_screen.dart';

class CriarContaScreen extends StatefulWidget {
  const CriarContaScreen({
    super.key,
  });

  @override
  State<CriarContaScreen> createState() =>
      _CriarContaScreenState();
}

class _CriarContaScreenState
    extends State<CriarContaScreen> {
  static const Color azulPrincipal =
      Color(0xFF1A7EF5);

  static const Color pretoPrincipal =
      Color(0xFF1A1A1A);

  static const Color cinzaTexto =
      Color(0xFF8A8A8A);

  final _formKey =
      GlobalKey<FormState>();

  final _nomeController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _telefoneController =
      TextEditingController();

  final _senhaController =
      TextEditingController();

  final _confirmarSenhaController =
      TextEditingController();

  final _placaGuinchoController =
      TextEditingController();

  String _tipoUsuario = 'cliente';
  String _tipoGuincho = 'Leve';

  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;
  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _placaGuinchoController.dispose();

    super.dispose();
  }

  Future<void> _criarConta() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nome =
        _nomeController.text.trim();

    final email =
        _emailController.text.trim();

    final telefone =
        _telefoneController.text.replaceAll(
      RegExp(r'\D'),
      '',
    );

    final placaGuincho =
        _placaGuinchoController.text
            .trim()
            .toUpperCase()
            .replaceAll(
              RegExp(r'[^A-Z0-9]'),
              '',
            );

    final senha =
        _senhaController.text;

    setState(() {
      _carregando = true;
    });

    try {
      await ApiService.instance.criarConta(
        nome: nome,
        email: email,
        telefone: telefone,
        senha: senha,
        tipo: _tipoUsuario,
        placaGuincho:
            _tipoUsuario == 'motorista'
                ? placaGuincho
                : null,
        tipoGuincho:
            _tipoUsuario == 'motorista'
                ? _tipoGuincho
                : null,
      );

      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      // IMPORTANTE:
      // Cadastro NÃO faz login e NÃO abre a Home.
      //
      // Vai para a confirmação do código.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ConfirmarEmailScreen(
            email: email,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.mensagem,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível criar sua conta.',
          ),
        ),
      );
    }
  }

  InputDecoration _decoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: cinzaTexto,
        fontSize: 14,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(
            0xFFDDDDDD,
          ),
          width: 1.5,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        borderSide:
            const BorderSide(
          color:
              azulPrincipal,
          width: 1.8,
        ),
      ),
      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        borderSide:
            const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        borderSide:
            const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _label(
    String texto,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Align(
        alignment:
            Alignment.centerLeft,
        child: Text(
          texto,
          style:
              const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.w600,
            color:
                pretoPrincipal,
          ),
        ),
      ),
    );
  }

  Widget _buildTipoConta({
    required String tipo,
    required String titulo,
    required String subtitulo,
    required IconData icone,
  }) {
    final selecionado =
        _tipoUsuario == tipo;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoUsuario = tipo;

          if (tipo != 'motorista') {
            _placaGuinchoController.clear();
            _tipoGuincho = 'Leve';
          }
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 180,
        ),
        padding:
            const EdgeInsets.all(
          14,
        ),
        decoration:
            BoxDecoration(
          color: selecionado
              ? azulPrincipal.withValues(
                  alpha: 0.08,
                )
              : Colors.white,
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          border:
              Border.all(
            color: selecionado
                ? azulPrincipal
                : const Color(
                    0xFFDDDDDD,
                  ),
            width:
                selecionado
                    ? 1.8
                    : 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icone,
              color: selecionado
                  ? azulPrincipal
                  : pretoPrincipal,
              size: 28,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              titulo,
              style:
                  TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w700,
                color: selecionado
                    ? azulPrincipal
                    : pretoPrincipal,
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            Text(
              subtitulo,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 11,
                color:
                    cinzaTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoGuincho({
    required String valor,
    required String titulo,
    required String subtitulo,
    required IconData icone,
  }) {
    final selecionado =
        _tipoGuincho == valor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoGuincho = valor;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        padding: const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: selecionado
              ? azulPrincipal.withValues(
                  alpha: 0.08,
                )
              : Colors.white,
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: selecionado
                ? azulPrincipal
                : const Color(
                    0xFFDDDDDD,
                  ),
            width: selecionado
                ? 1.8
                : 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icone,
              color: selecionado
                  ? azulPrincipal
                  : pretoPrincipal,
              size: 28,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selecionado
                    ? azulPrincipal
                    : pretoPrincipal,
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: cinzaTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.white,
      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation: 0,
        centerTitle: true,
        title:
            const Text(
          'Criar conta',
          style:
              TextStyle(
            color:
                pretoPrincipal,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
      body:
          SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets
                  .fromLTRB(
            28,
            18,
            28,
            32,
          ),
          child: Form(
            key:
                _formKey,
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration:
                      BoxDecoration(
                    color:
                        azulPrincipal
                            .withValues(
                      alpha: 0.1,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      const Icon(
                    Icons
                        .person_add_alt_1_rounded,
                    color:
                        azulPrincipal,
                    size: 34,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                const Text(
                  'Crie sua conta no Hook',
                  style:
                      TextStyle(
                    fontSize: 23,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        pretoPrincipal,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                const Text(
                  'Depois enviaremos um código para confirmar seu e-mail.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    fontSize: 13,
                    color:
                        cinzaTexto,
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                _label(
                  'Tipo de conta',
                ),

                Row(
                  children: [
                    Expanded(
                      child: _buildTipoConta(
                        tipo: 'cliente',
                        titulo: 'Cliente',
                        subtitulo:
                            'Preciso de socorro',
                        icone:
                            Icons.person_outline_rounded,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: _buildTipoConta(
                        tipo: 'motorista',
                        titulo: 'Motorista',
                        subtitulo:
                            'Presto socorro',
                        icone:
                            Icons.local_shipping_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 24,
                ),

                _label(
                  'Nome completo',
                ),

                TextFormField(
                  controller:
                      _nomeController,
                  textCapitalization:
                      TextCapitalization
                          .words,
                  decoration:
                      _decoration(
                    hint:
                        'Seu nome completo',
                  ),
                  validator:
                      (value) {
                    if (value ==
                            null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Informe seu nome.';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 18,
                ),

                _label(
                  'E-mail',
                ),

                TextFormField(
                  controller:
                      _emailController,
                  keyboardType:
                      TextInputType
                          .emailAddress,
                  decoration:
                      _decoration(
                    hint:
                        'nome@exemplo.com',
                  ),
                  validator:
                      (value) {
                    final email =
                        value
                            ?.trim() ??
                            '';

                    if (email
                        .isEmpty) {
                      return 'Informe seu e-mail.';
                    }

                    if (!email
                            .contains(
                          '@',
                        ) ||
                        !email
                            .contains(
                          '.',
                        )) {
                      return 'Informe um e-mail válido.';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 18,
                ),

                _label(
                  'Telefone',
                ),

                TextFormField(
                  controller:
                      _telefoneController,
                  keyboardType:
                      TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly,
                    TelefoneInputFormatter(),
                  ],
                  decoration:
                      _decoration(
                    hint:
                        '(00) 00000-0000',
                  ),
                  validator:
                      (value) {
                    if (value ==
                            null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Informe seu telefone.';
                    }

                    final numeros =
                        value.replaceAll(
                      RegExp(r'\D'),
                      '',
                    );

                    if (numeros.length !=
                        11) {
                      return 'Informe um celular válido.';
                    }

                    return null;
                  },
                ),

                if (_tipoUsuario ==
                    'motorista') ...[
                  const SizedBox(
                    height: 18,
                  ),

                  _label(
                    'Placa do guincho',
                  ),

                  TextFormField(
                    controller:
                        _placaGuinchoController,
                    textCapitalization:
                        TextCapitalization
                            .characters,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .allow(
                        RegExp(
                          r'[A-Za-z0-9-]',
                        ),
                      ),
                      LengthLimitingTextInputFormatter(
                        8,
                      ),
                    ],
                    decoration:
                        _decoration(
                      hint:
                          'ABC1D23',
                    ),
                    validator:
                        (value) {
                      if (_tipoUsuario !=
                          'motorista') {
                        return null;
                      }

                      final placa =
                          (value ?? '')
                              .replaceAll(
                        RegExp(
                          r'[^A-Za-z0-9]',
                        ),
                        '',
                      );

                      if (placa.length !=
                          7) {
                        return 'Informe uma placa válida.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  _label(
                    'Tipo de guincho',
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTipoGuincho(
                          valor: 'Leve',
                          titulo: 'Guincho Leve',
                          subtitulo:
                              'Veículos de passeio',
                          icone:
                              Icons.local_shipping_outlined,
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child: _buildTipoGuincho(
                          valor: 'Pesado',
                          titulo: 'Guincho Pesado',
                          subtitulo:
                              'Veículos maiores',
                          icone:
                              Icons.fire_truck_outlined,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(
                  height: 18,
                ),

                _label(
                  'Senha',
                ),

                TextFormField(
                  controller:
                      _senhaController,
                  obscureText:
                      !_senhaVisivel,
                  decoration:
                      _decoration(
                    hint:
                        '••••••••',
                    suffixIcon:
                        IconButton(
                      onPressed:
                          () {
                        setState(
                          () {
                            _senhaVisivel =
                                !_senhaVisivel;
                          },
                        );
                      },
                      icon: Icon(
                        _senhaVisivel
                            ? Icons
                                .visibility_off_outlined
                            : Icons
                                .visibility_outlined,
                        color:
                            cinzaTexto,
                      ),
                    ),
                  ),
                  validator:
                      (value) {
                    if (value ==
                            null ||
                        value
                            .isEmpty) {
                      return 'Informe uma senha.';
                    }

                    if (value
                            .length <
                        6) {
                      return 'A senha deve ter pelo menos 6 caracteres.';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 18,
                ),

                _label(
                  'Confirmar senha',
                ),

                TextFormField(
                  controller:
                      _confirmarSenhaController,
                  obscureText:
                      !_confirmarSenhaVisivel,
                  decoration:
                      _decoration(
                    hint:
                        '••••••••',
                    suffixIcon:
                        IconButton(
                      onPressed:
                          () {
                        setState(
                          () {
                            _confirmarSenhaVisivel =
                                !_confirmarSenhaVisivel;
                          },
                        );
                      },
                      icon: Icon(
                        _confirmarSenhaVisivel
                            ? Icons
                                .visibility_off_outlined
                            : Icons
                                .visibility_outlined,
                        color:
                            cinzaTexto,
                      ),
                    ),
                  ),
                  validator:
                      (value) {
                    if (value !=
                        _senhaController
                            .text) {
                      return 'As senhas não coincidem.';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 28,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 54,
                  child:
                      ElevatedButton(
                    onPressed:
                        _carregando
                            ? null
                            : _criarConta,
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          azulPrincipal,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                      elevation:
                          0,
                    ),
                    child:
                        _carregando
                            ? const SizedBox(
                                width:
                                    22,
                                height:
                                    22,
                                child:
                                    CircularProgressIndicator(
                                  color:
                                      Colors.white,
                                  strokeWidth:
                                      2.5,
                                ),
                              )
                            : const Text(
                                'Criar conta',
                                style:
                                    TextStyle(
                                  fontSize:
                                      16,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                TextButton(
                  onPressed:
                      () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child:
                      const Text(
                    'Já tenho uma conta',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MÁSCARA DE TELEFONE
// (00) 00000-0000
// ============================================================

class TelefoneInputFormatter
    extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var numeros =
        newValue.text.replaceAll(
      RegExp(r'\D'),
      '',
    );

    if (numeros.length > 11) {
      numeros =
          numeros.substring(
        0,
        11,
      );
    }

    String texto = '';

    if (numeros.isNotEmpty) {
      final fimDdd =
          numeros.length < 2
              ? numeros.length
              : 2;

      texto =
          '(${numeros.substring(0, fimDdd)}';
    }

    if (numeros.length >= 2) {
      texto += ') ';
    }

    if (numeros.length > 2) {
      final fimNumero =
          numeros.length < 7
              ? numeros.length
              : 7;

      texto += numeros.substring(
        2,
        fimNumero,
      );
    }

    if (numeros.length > 7) {
      texto +=
          '-${numeros.substring(7)}';
    }

    return TextEditingValue(
      text: texto,
      selection:
          TextSelection.collapsed(
        offset: texto.length,
      ),
    );
  }
}

