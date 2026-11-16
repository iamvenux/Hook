import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';

class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({
    super.key,
  });

  @override
  State<EsqueciSenhaScreen> createState() =>
      _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState
    extends State<EsqueciSenhaScreen> {
  static const Color azulPrincipal =
      Color(0xFF1A7EF5);

  static const Color pretoPrincipal =
      Color(0xFF1A1A1A);

  static const Color cinzaTexto =
      Color(0xFF8A8A8A);

  static const Color cinzaFundo =
      Color(0xFFF5F5F5);

  final _emailController =
      TextEditingController();

  final _codigoController =
      TextEditingController();

  final _novaSenhaController =
      TextEditingController();

  final _confirmarSenhaController =
      TextEditingController();

  int _etapa = 0;

  bool _carregando = false;
  bool _reenviando = false;

  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;

  String _email = '';
  String _codigoValidado = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();

    super.dispose();
  }

  // ============================================================
  // ETAPA 1 - ENVIAR CÓDIGO
  // ============================================================

  Future<void> _enviarCodigo() async {
    final email =
        _emailController.text.trim();

    if (email.isEmpty ||
        !email.contains('@') ||
        !email.contains('.')) {
      _mostrarMensagem(
        'Informe um e-mail válido.',
      );

      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final resposta =
          await ApiService.instance
              .solicitarRecuperacaoSenha(
        email: email,
      );

      if (!mounted) return;

      setState(() {
        _email = email;
        _carregando = false;
        _etapa = 1;
      });

      _mostrarMensagem(
        resposta['mensagem']
                ?.toString() ??
            'Se existir uma conta com este e-mail, enviaremos um código.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        e.mensagem,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        'Não foi possível solicitar a recuperação da senha.',
      );
    }
  }

  // ============================================================
  // REENVIAR CÓDIGO
  // ============================================================

  Future<void> _reenviarCodigo() async {
    if (_reenviando ||
        _email.isEmpty) {
      return;
    }

    setState(() {
      _reenviando = true;
    });

    try {
      /*
       * IMPORTANTE:
       * Reenviar no "Esqueci a senha" chama NOVAMENTE
       * solicitar_recuperacao_senha.php.
       *
       * Não usa o endpoint de verificação de cadastro.
       */
      final resposta =
          await ApiService.instance
              .solicitarRecuperacaoSenha(
        email: _email,
      );

      if (!mounted) return;

      setState(() {
        _reenviando = false;

        // Limpa o código anterior para o usuário
        // digitar o novo.
        _codigoController.clear();
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

  // ============================================================
  // ETAPA 2 - VALIDAR CÓDIGO
  // ============================================================

  Future<void> _validarCodigo() async {
    final codigo =
        _codigoController.text.trim();

    if (codigo.length != 6) {
      _mostrarMensagem(
        'Digite o código de 6 dígitos.',
      );

      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      await ApiService.instance
          .validarCodigoRecuperacao(
        email: _email,
        codigo: codigo,
      );

      if (!mounted) return;

      setState(() {
        _codigoValidado = codigo;
        _carregando = false;
        _etapa = 2;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        e.mensagem,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        'Não foi possível validar o código.',
      );
    }
  }

  // ============================================================
  // ETAPA 3 - NOVA SENHA
  // ============================================================

  Future<void> _alterarSenha() async {
    final senha =
        _novaSenhaController.text;

    final confirmar =
        _confirmarSenhaController.text;

    if (senha.length < 6) {
      _mostrarMensagem(
        'A nova senha deve ter pelo menos 6 caracteres.',
      );

      return;
    }

    if (senha != confirmar) {
      _mostrarMensagem(
        'As senhas não coincidem.',
      );

      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final resposta =
          await ApiService.instance
              .redefinirSenha(
        email: _email,
        codigo: _codigoValidado,
        novaSenha: senha,
      );

      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 48,
            ),
            title: const Text(
              'Senha alterada!',
            ),
            content: Text(
              resposta['mensagem']
                      ?.toString() ??
                  'Sua senha foi alterada com sucesso. Faça login para continuar.',
              textAlign: TextAlign.center,
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
                child: const Text(
                  'Ir para o login',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        e.mensagem,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        'Não foi possível alterar sua senha.',
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

  // ============================================================
  // BUILD
  // ============================================================

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
        title: const Text(
          'Recuperar senha',
          style: TextStyle(
            color:
                pretoPrincipal,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child:
            AnimatedSwitcher(
          duration:
              const Duration(
            milliseconds: 250,
          ),
          child:
              _buildEtapaAtual(),
        ),
      ),
    );
  }

  Widget _buildEtapaAtual() {
    switch (_etapa) {
      case 1:
        return _buildCodigo();

      case 2:
        return _buildNovaSenha();

      case 0:
      default:
        return _buildEmail();
    }
  }

  // ============================================================
  // ETAPA EMAIL
  // ============================================================

  Widget _buildEmail() {
    return SingleChildScrollView(
      key:
          const ValueKey(
        'email',
      ),
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
          _iconeTopo(
            Icons
                .lock_reset_rounded,
          ),

          const SizedBox(
            height: 24,
          ),

          const Text(
            'Esqueceu sua senha?',
            textAlign:
                TextAlign.center,
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
            'Informe o e-mail da sua conta e enviaremos um código para redefinir sua senha.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize: 14,
              height: 1.45,
              color:
                  cinzaTexto,
            ),
          ),

          const SizedBox(
            height: 32,
          ),

          Align(
            alignment:
                Alignment.centerLeft,
            child:
                const Text(
              'E-mail',
              style:
                  TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
                color:
                    pretoPrincipal,
              ),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          TextField(
            controller:
                _emailController,
            keyboardType:
                TextInputType
                    .emailAddress,
            decoration:
                _inputDecoration(
              hint:
                  'nome@exemplo.com',
            ),
          ),

          const SizedBox(
            height: 26,
          ),

          _botaoPrincipal(
            texto:
                'Enviar código',
            carregando:
                _carregando,
            onPressed:
                _enviarCodigo,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ETAPA CÓDIGO
  //
  // MESMO PADRÃO VISUAL DA CONFIRMAÇÃO DE CADASTRO
  // ============================================================

  Widget _buildCodigo() {
    return SingleChildScrollView(
      key:
          const ValueKey(
        'codigo',
      ),
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
          _iconeTopo(
            Icons
                .mark_email_read_outlined,
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
            _email,
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
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter
                  .digitsOnly,
            ],
            style:
                const TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
              letterSpacing: 10,
            ),
            decoration:
                InputDecoration(
              counterText: '',
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
              filled: true,
              fillColor:
                  cinzaFundo,
              contentPadding:
                  const EdgeInsets
                      .symmetric(
                vertical: 20,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  14,
                ),
                borderSide:
                    BorderSide.none,
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius
                        .circular(
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

          _botaoPrincipal(
            texto:
                'Confirmar código',
            carregando:
                _carregando,
            onPressed:
                _validarCodigo,
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
                    : _reenviarCodigo,
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
    );
  }

  // ============================================================
  // ETAPA NOVA SENHA
  // ============================================================

  Widget _buildNovaSenha() {
    return SingleChildScrollView(
      key:
          const ValueKey(
        'novaSenha',
      ),
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
          _iconeTopo(
            Icons
                .password_rounded,
          ),

          const SizedBox(
            height: 24,
          ),

          const Text(
            'Crie uma nova senha',
            textAlign:
                TextAlign.center,
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
            'Escolha uma nova senha para acessar sua conta.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize: 14,
              color:
                  cinzaTexto,
            ),
          ),

          const SizedBox(
            height: 32,
          ),

          const Align(
            alignment:
                Alignment.centerLeft,
            child: Text(
              'Nova senha',
              style:
                  TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
                color:
                    pretoPrincipal,
              ),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          TextField(
            controller:
                _novaSenhaController,
            obscureText:
                !_senhaVisivel,
            decoration:
                _inputDecoration(
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
          ),

          const SizedBox(
            height: 18,
          ),

          const Align(
            alignment:
                Alignment.centerLeft,
            child: Text(
              'Confirmar senha',
              style:
                  TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w600,
                color:
                    pretoPrincipal,
              ),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          TextField(
            controller:
                _confirmarSenhaController,
            obscureText:
                !_confirmarSenhaVisivel,
            decoration:
                _inputDecoration(
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
          ),

          const SizedBox(
            height: 28,
          ),

          _botaoPrincipal(
            texto:
                'Alterar senha',
            carregando:
                _carregando,
            onPressed:
                _alterarSenha,
          ),
        ],
      ),
    );
  }

  Widget _iconeTopo(
    IconData icone,
  ) {
    return Container(
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
      child: Icon(
        icone,
        size: 40,
        color:
            azulPrincipal,
      ),
    );
  }

  Widget _botaoPrincipal({
    required String texto,
    required bool carregando,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width:
          double.infinity,
      height: 54,
      child:
          ElevatedButton(
        onPressed:
            carregando
                ? null
                : onPressed,
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
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius
                    .circular(
              12,
            ),
          ),
        ),
        child:
            carregando
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
                : Text(
                    texto,
                    style:
                        const TextStyle(
                      fontSize:
                          16,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(
        color:
            cinzaTexto,
      ),
      suffixIcon:
          suffixIcon,
      filled: true,
      fillColor:
          Colors.white,
      contentPadding:
          const EdgeInsets
              .symmetric(
        horizontal: 18,
        vertical: 18,
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
    );
  }
}
