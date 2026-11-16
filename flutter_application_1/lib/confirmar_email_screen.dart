import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';

class ConfirmarEmailScreen
    extends StatefulWidget {
  final String email;

  const ConfirmarEmailScreen({
    super.key,
    required this.email,
  });

  @override
  State<ConfirmarEmailScreen>
      createState() =>
          _ConfirmarEmailScreenState();
}

class _ConfirmarEmailScreenState
    extends State<ConfirmarEmailScreen> {
  static const Color azulPrincipal =
      Color(0xFF1A7EF5);

  static const Color pretoPrincipal =
      Color(0xFF1A1A1A);

  static const Color cinzaTexto =
      Color(0xFF8A8A8A);

  final _codigoController =
      TextEditingController();

  bool _verificando = false;
  bool _reenviando = false;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final codigo =
        _codigoController.text.trim();

    if (codigo.length != 6) {
      _mostrarMensagem(
        'Digite o código de 6 dígitos.',
      );

      return;
    }

    setState(() {
      _verificando = true;
    });

    try {
      final resposta =
          await ApiService.instance
              .verificarEmail(
        email: widget.email,
        codigo: codigo,
      );

      if (!mounted) return;

      setState(() {
        _verificando = false;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(
              Icons
                  .check_circle_rounded,
              color: Colors.green,
              size: 48,
            ),
            title:
                const Text(
              'E-mail confirmado!',
            ),
            content:
                Text(
              resposta['mensagem']
                      ?.toString() ??
                  'Sua conta foi criada com sucesso. Faça login para continuar.',
              textAlign:
                  TextAlign.center,
            ),
            actionsAlignment:
                MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },
                child:
                    const Text(
                  'Ir para o login',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      // Login -> Criar conta -> Confirmar e-mail
      //
      // Volta até a primeira rota, que é Login.
      // NÃO abre Home automaticamente.
      Navigator.of(context).popUntil(
        (route) =>
            route.isFirst,
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _verificando = false;
      });

      _mostrarMensagem(
        e.mensagem,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _verificando = false;
      });

      _mostrarMensagem(
        'Não foi possível verificar o código.',
      );
    }
  }

  Future<void> _reenviar() async {
    if (_reenviando) {
      return;
    }

    setState(() {
      _reenviando = true;
    });

    try {
      final resposta =
          await ApiService.instance
              .reenviarCodigoVerificacao(
        email: widget.email,
      );

      if (!mounted) return;

      setState(() {
        _reenviando = false;
      });

      _mostrarMensagem(
        resposta['mensagem']
                ?.toString() ??
            'Novo código enviado.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _reenviando = false;
      });

      _mostrarMensagem(
        e.mensagem,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _reenviando = false;
      });

      _mostrarMensagem(
        'Não foi possível reenviar o código.',
      );
    }
  }

  void _mostrarMensagem(
    String mensagem,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          mensagem,
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
        title:
            const Text(
          'Confirmar e-mail',
          style:
              TextStyle(
            color:
                pretoPrincipal,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets
                  .fromLTRB(
            30,
            32,
            30,
            32,
          ),
          child: Column(
            children: [
              Container(
                width: 86,
                height: 86,
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
                      .mark_email_read_outlined,
                  size: 40,
                  color:
                      azulPrincipal,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              const Text(
                'Confira seu e-mail',
                style:
                    TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      pretoPrincipal,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              const Text(
                'Enviamos um código de 6 dígitos para',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color:
                      cinzaTexto,
                  fontSize: 14,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                widget.email,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      azulPrincipal,
                  fontWeight:
                      FontWeight.w700,
                  fontSize: 14,
                ),
              ),

              const SizedBox(
                height: 32,
              ),

              TextField(
                controller:
                    _codigoController,
                autofocus:
                    true,
                textAlign:
                    TextAlign.center,
                keyboardType:
                    TextInputType.number,
                maxLength:
                    6,
                inputFormatters: [
                  FilteringTextInputFormatter
                      .digitsOnly,
                ],
                style:
                    const TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                  letterSpacing:
                      10,
                ),
                decoration:
                    InputDecoration(
                  counterText:
                      '',
                  hintText:
                      '000000',
                  hintStyle:
                      TextStyle(
                    color:
                        Colors.grey
                            .shade300,
                    letterSpacing:
                        10,
                  ),
                  filled:
                      true,
                  fillColor:
                      const Color(
                    0xFFF5F5F5,
                  ),
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 20,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          azulPrincipal,
                      width: 1.7,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              SizedBox(
                width:
                    double.infinity,
                height: 54,
                child:
                    ElevatedButton(
                  onPressed:
                      _verificando
                          ? null
                          : _confirmar,
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
                      _verificando
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
                              'Confirmar código',
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

              const Text(
                'Não recebeu o código?',
                style:
                    TextStyle(
                  fontSize: 13,
                  color:
                      cinzaTexto,
                ),
              ),

              TextButton(
                onPressed:
                    _reenviando
                        ? null
                        : _reenviar,
                child: Text(
                  _reenviando
                      ? 'Enviando...'
                      : 'Reenviar código',
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'O código expira em 10 minutos.',
                style:
                    TextStyle(
                  fontSize: 12,
                  color:
                      cinzaTexto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
