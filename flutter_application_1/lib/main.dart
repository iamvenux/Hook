import 'package:flutter/material.dart';

import 'criar_conta_screen.dart';
import 'esqueci_senha_screen.dart';
import 'home.dart';
import 'home_socorrista_screen.dart';
import 'api_service.dart';

void main() {
  runApp(const HookApp());
}

class HookApp extends StatelessWidget {
  const HookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A7EF5),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController =
      TextEditingController();

  final _senhaController =
      TextEditingController();

  bool _senhaVisivel = false;
  bool _carregando = false;

  static const Color azulPrincipal =
      Color(0xFF1A7EF5);

  static const Color cinzaTexto =
      Color(0xFF8A8A8A);

  static const Color pretoPrincipal =
      Color(0xFF1A1A1A);

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    final email =
        _emailController.text.trim();

    final senha =
        _senhaController.text;

    try {
      final usuario =
          await ApiService.instance.login(
        email: email,
        senha: senha,
      );

      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      final tipo =
          usuario['tipo']?.toString();

      if (tipo == 'motorista') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const HomeSocorristaScreen(),
          ),
        );
      } else if (tipo == 'cliente') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const HomeScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Tipo de usuário inválido.',
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.mensagem),
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
            'Não foi possível conectar ao servidor. Verifique se Apache e MySQL estão ligados.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),

                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                      colors: [
                        Color(0xFF2E8FF7),
                        Color(0xFF1565D8),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      26,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: azulPrincipal
                            .withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 20,
                        offset:
                            const Offset(
                          0,
                          8,
                        ),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Bem-vindo',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                    color: azulPrincipal,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Inicie sessão para usar o Hook',
                  style: TextStyle(
                    fontSize: 15,
                    color: cinzaTexto,
                  ),
                ),

                const SizedBox(height: 44),

                const Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          pretoPrincipal,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      _emailController,
                  keyboardType:
                      TextInputType
                          .emailAddress,
                  style: const TextStyle(
                    fontSize: 15,
                    color: pretoPrincipal,
                  ),
                  decoration:
                      InputDecoration(
                    hintText:
                        'nome@exemplo.com',
                    hintStyle:
                        const TextStyle(
                      color: cinzaTexto,
                    ),
                    contentPadding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(12),
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
                          BorderRadius
                              .circular(12),
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
                          BorderRadius
                              .circular(12),
                      borderSide:
                          const BorderSide(
                        color: Colors.red,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Informe seu email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    const Text(
                      'Senha',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            pretoPrincipal,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const EsqueciSenhaScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Esqueceu a senha?',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              azulPrincipal,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller:
                      _senhaController,
                  obscureText:
                      !_senhaVisivel,
                  style: const TextStyle(
                    fontSize: 15,
                    color: pretoPrincipal,
                  ),
                  decoration:
                      InputDecoration(
                    hintText: '••••••••',
                    hintStyle:
                        const TextStyle(
                      color: cinzaTexto,
                      fontSize: 18,
                    ),
                    contentPadding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _senhaVisivel
                            ? Icons
                                .visibility_off_outlined
                            : Icons
                                .visibility_outlined,
                        color:
                            cinzaTexto,
                      ),
                      onPressed: () {
                        setState(() {
                          _senhaVisivel =
                              !_senhaVisivel;
                        });
                      },
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(12),
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
                          BorderRadius
                              .circular(12),
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
                          BorderRadius
                              .circular(12),
                      borderSide:
                          const BorderSide(
                        color: Colors.red,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Informe sua senha';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child:
                      ElevatedButton(
                    onPressed: _carregando
                        ? null
                        : _fazerLogin,
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          azulPrincipal,
                      foregroundColor:
                          Colors.white,
                      disabledBackgroundColor:
                          azulPrincipal
                              .withValues(
                        alpha: 0.6,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: _carregando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.white,
                              strokeWidth:
                                  2.5,
                            ),
                          )
                        : const Text(
                            'Entre',
                            style:
                                TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    const Text(
                      'Ainda não tem cadastro? ',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            cinzaTexto,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const CriarContaScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Criar conta',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              azulPrincipal,
                          fontWeight:
                              FontWeight.w600,
                        ),
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
}