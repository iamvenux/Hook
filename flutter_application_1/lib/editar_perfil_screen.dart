import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';
import 'perfil_componentes.dart';

const Color _azul = Color(0xFF1A7EF5);
const Color _preto = Color(0xFF1A1A1A);
const Color _cinzaTexto = Color(0xFF8A8A8A);
const Color _cinzaFundo = Color(0xFFF5F5F5);

/// Tela de edição de perfil (cliente e motorista).
/// Nome, telefone e foto são salvos direto (com validação no servidor).
/// O e-mail só muda depois de confirmar um código enviado ao novo endereço.
class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;

  bool _salvando = false;
  bool _enviandoFoto = false;

  @override
  void initState() {
    super.initState();

    _nomeController = TextEditingController(
      text: ApiService.instance.nomeUsuario ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  String get _email => ApiService.instance.emailUsuario ?? '';

  String get _telefone => ApiService.instance.telefoneUsuario ?? '';

  // ----------------------------------------------------------
  // FOTO DE PERFIL
  // ----------------------------------------------------------

  Future<void> _abrirOpcoesFoto() async {
    final temFoto = (ApiService.instance.fotoUsuario ?? '').isNotEmpty;

    final escolha = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Foto de perfil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _preto,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (!kIsWeb)
                _opcaoFoto(
                  ctx,
                  Icons.photo_camera_outlined,
                  'Tirar foto',
                  'camera',
                ),
              _opcaoFoto(
                ctx,
                Icons.photo_library_outlined,
                'Escolher da galeria',
                'galeria',
              ),
              if (temFoto)
                _opcaoFoto(
                  ctx,
                  Icons.delete_outline_rounded,
                  'Remover foto',
                  'remover',
                  perigo: true,
                ),
            ],
          ),
        ),
      ),
    );

    if (escolha == null || !mounted) return;

    if (escolha == 'remover') {
      await _removerFoto();
    } else {
      await _trocarFoto(
        escolha == 'camera' ? ImageSource.camera : ImageSource.gallery,
      );
    }
  }

  Widget _opcaoFoto(
    BuildContext ctx,
    IconData icone,
    String titulo,
    String valor, {
    bool perigo = false,
  }) {
    final cor = perigo ? const Color(0xFFEF4444) : _azul;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: perigo ? const Color(0xFFFDECEC) : const Color(0xFFE8F2FE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icone, color: cor, size: 20),
      ),
      title: Text(
        titulo,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: perigo ? cor : _preto,
        ),
      ),
      onTap: () => Navigator.pop(ctx, valor),
    );
  }

  Future<void> _trocarFoto(ImageSource origem) async {
    try {
      final imagem = await ImagePicker().pickImage(
        source: origem,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (imagem == null || !mounted) return;

      setState(() => _enviandoFoto = true);

      final bytes = await imagem.readAsBytes();

      await ApiService.instance.enviarFotoPerfil(
        bytes,
        imagem.name.isEmpty ? 'foto.jpg' : imagem.name,
      );

      if (!mounted) return;

      _aviso('Foto atualizada.', sucesso: true);
    } on ApiException catch (e) {
      _aviso(e.mensagem);
    } catch (_) {
      _aviso('Não foi possível enviar a foto. Tente novamente.');
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  Future<void> _removerFoto() async {
    setState(() => _enviandoFoto = true);

    try {
      await ApiService.instance.removerFotoPerfil();

      if (!mounted) return;

      _aviso('Foto removida.', sucesso: true);
    } on ApiException catch (e) {
      _aviso(e.mensagem);
    } catch (_) {
      _aviso('Não foi possível remover a foto.');
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  Future<void> _salvarNome() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _salvando = true);

    try {
      await ApiService.instance.atualizarPerfil(
        nome: _nomeController.text.trim(),
        telefone: _telefone,
      );

      if (!mounted) return;

      _aviso('Perfil atualizado com sucesso.', sucesso: true);

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _aviso(e.mensagem);
    } catch (_) {
      _aviso('Não foi possível atualizar o perfil.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _alterarContato({required bool email}) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AlterarContatoSheet(
        email: email,
        nomeAtual: _nomeController.text.trim().isEmpty
            ? (ApiService.instance.nomeUsuario ?? '')
            : _nomeController.text.trim(),
        emailAtual: _email,
        telefoneAtual: _telefone,
      ),
    );

    if (ok == true && mounted) {
      setState(() {});

      _aviso(
        email ? 'E-mail atualizado.' : 'Telefone atualizado.',
        sucesso: true,
      );
    }
  }

  void _aviso(String texto, {bool sucesso = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: sucesso ? const Color(0xFF16A34A) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome = _nomeController.text.trim().isEmpty
        ? (ApiService.instance.nomeUsuario ?? '')
        : _nomeController.text.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _preto),
        title: const Text(
          'Editar perfil',
          style: TextStyle(color: _preto, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _enviandoFoto ? null : _abrirOpcoesFoto,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AvatarUsuario(
                        nome: nome,
                        fotoUrl: ApiService.instance.fotoUsuario,
                        tamanho: 96,
                      ),
                      if (_enviandoFoto)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _azul,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.photo_camera_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _enviandoFoto ? null : _abrirOpcoesFoto,
                  child: const Text(
                    'Alterar foto',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _azul,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Nome completo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _preto,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nomeController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoracao('Seu nome'),
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe seu nome.'
                    : null,
              ),
              const SizedBox(height: 26),
              const Text(
                'CONTATO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _cinzaTexto,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              _cartaoContato(
                icone: Icons.email_outlined,
                rotulo: 'E-mail',
                valor: _email.isEmpty ? 'Não informado' : _email,
                aoAlterar: () => _alterarContato(email: true),
              ),
              const SizedBox(height: 10),
              _cartaoContato(
                icone: Icons.phone_outlined,
                rotulo: 'Telefone',
                valor: _telefone.isEmpty ? 'Não informado' : formatarTelefone(_telefone),
                aoAlterar: () => _alterarContato(email: false),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.only(left: 2, top: 4),
                child: Text(
                  'Para alterar o e-mail, enviamos um código de confirmação '
                  'para o novo endereço.',
                  style: TextStyle(fontSize: 12, color: _cinzaTexto),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvarNome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _azul,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                          'Salvar alterações',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cartaoContato({
    required IconData icone,
    required String rotulo,
    required String valor,
    required VoidCallback aoAlterar,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: _cinzaFundo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icone, color: _cinzaTexto, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _cinzaTexto,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _preto,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: aoAlterar,
            child: const Text(
              'Alterar',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _azul,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoracao(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _cinzaTexto),
      filled: true,
      fillColor: _cinzaFundo,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _azul, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}

// ==============================================================
// FOLHA: ALTERAR E-MAIL (COM CÓDIGO REAL) / TELEFONE (DIRETO)
// ==============================================================

class _AlterarContatoSheet extends StatefulWidget {
  final bool email;
  final String nomeAtual;
  final String emailAtual;
  final String telefoneAtual;

  const _AlterarContatoSheet({
    required this.email,
    required this.nomeAtual,
    required this.emailAtual,
    required this.telefoneAtual,
  });

  @override
  State<_AlterarContatoSheet> createState() => _AlterarContatoSheetState();
}

class _AlterarContatoSheetState extends State<_AlterarContatoSheet> {
  final _valorController = TextEditingController();
  final _codigoController = TextEditingController();

  /// 0 = digitar o novo valor, 1 = digitar o código recebido (só e-mail)
  int _etapa = 0;
  bool _carregando = false;
  String? _erro;

  String get _rotulo => widget.email ? 'e-mail' : 'telefone';

  @override
  void dispose() {
    _valorController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  String _somenteDigitos(String v) => v.replaceAll(RegExp(r'\D'), '');

  String? _validarValor(String v) {
    final valor = v.trim();

    if (widget.email) {
      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(valor);

      if (!ok) return 'Informe um e-mail válido.';

      if (valor.toLowerCase() == widget.emailAtual.toLowerCase()) {
        return 'Este já é o seu e-mail atual.';
      }
    } else {
      final digitos = _somenteDigitos(valor);

      if (digitos.length < 10 || digitos.length > 11) {
        return 'Informe um telefone com DDD.';
      }

      if (digitos == _somenteDigitos(widget.telefoneAtual)) {
        return 'Este já é o seu telefone atual.';
      }
    }

    return null;
  }

  /// E-mail: pede o código ao servidor. Telefone: salva direto.
  Future<void> _continuar() async {
    final erro = _validarValor(_valorController.text);

    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      if (widget.email) {
        await ApiService.instance.solicitarTrocaEmail(
          _valorController.text.trim(),
        );

        if (!mounted) return;

        setState(() {
          _carregando = false;
          _etapa = 1;
        });
      } else {
        await ApiService.instance.atualizarPerfil(
          nome: widget.nomeAtual,
          telefone: _somenteDigitos(_valorController.text),
        );

        if (!mounted) return;

        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = e.mensagem;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = widget.email
            ? 'Não foi possível enviar o código. Verifique a conexão.'
            : 'Não foi possível salvar. Tente novamente.';
      });
    }
  }

  Future<void> _reenviar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await ApiService.instance.solicitarTrocaEmail(
        _valorController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _carregando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código reenviado.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = e.mensagem;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = 'Não foi possível reenviar o código.';
      });
    }
  }

  Future<void> _confirmar() async {
    final codigo = _codigoController.text.trim();

    if (codigo.length != 6) {
      setState(() => _erro = 'Digite o código de 6 dígitos.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await ApiService.instance.confirmarTrocaEmail(codigo);

      if (!mounted) return;

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = e.mensagem;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = 'Não foi possível confirmar. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _etapa == 0 ? 'Alterar $_rotulo' : 'Confirme o código',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _preto,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _etapa == 1
                  ? 'Enviamos um código de 6 dígitos para '
                      '${_valorController.text.trim()}. '
                      'Se não encontrar, olhe também o spam.'
                  : widget.email
                      ? 'Informe o novo e-mail. Vamos enviar um código '
                          'para ele confirmar que é seu.'
                      : 'Informe o novo telefone com DDD.',
              style: const TextStyle(fontSize: 14, color: _cinzaTexto),
            ),
            const SizedBox(height: 18),
            if (_etapa == 0)
              TextField(
                controller: _valorController,
                autofocus: true,
                keyboardType: widget.email
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                inputFormatters: widget.email
                    ? null
                    : [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9()\-\s+]')),
                      ],
                decoration: _campo(
                  widget.email ? 'novo@email.com' : '(11) 99999-9999',
                ),
                onChanged: (_) {
                  if (_erro != null) setState(() => _erro = null);
                },
                onSubmitted: (_) => _continuar(),
              )
            else ...[
              TextField(
                controller: _codigoController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                ),
                decoration: _campo('000000').copyWith(counterText: ''),
                onChanged: (_) {
                  if (_erro != null) setState(() => _erro = null);
                },
                onSubmitted: (_) => _confirmar(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _carregando ? null : _reenviar,
                  child: const Text('Reenviar código'),
                ),
              ),
            ],
            if (_erro != null) ...[
              const SizedBox(height: 6),
              Text(
                _erro!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _carregando
                    ? null
                    : (_etapa == 0 ? _continuar : _confirmar),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _azul,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _carregando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _etapa == 1
                            ? 'Confirmar'
                            : (widget.email ? 'Enviar código' : 'Salvar'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _campo(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _cinzaTexto),
      filled: true,
      fillColor: _cinzaFundo,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _azul, width: 1.5),
      ),
    );
  }
}
