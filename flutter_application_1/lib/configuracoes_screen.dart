import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'enderecos_store.dart';
import 'main.dart' show LoginScreen;

const Color _azul = Color(0xFF1A7EF5);
const Color _preto = Color(0xFF1A1A1A);
const Color _cinzaTexto = Color(0xFF8A8A8A);
const Color _cinzaFundo = Color(0xFFF5F5F5);
const Color _vermelho = Color(0xFFEF4444);

/// Configurações do app (cliente e motorista).
/// As preferências ficam salvas no aparelho, por usuário.
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  static const _padroes = <String, bool>{
    'notif_status': true,
    'notif_chat': true,
    'notif_promocoes': false,
    'compartilhar_local': true,
    'confirmar_antes_pedir': true,
  };

  Map<String, bool> _valores = Map.of(_padroes);
  bool _carregando = true;

  bool get _ehMotorista => ApiService.instance.ehMotorista;

  String _chave(String nome) =>
      'cfg_${nome}_${ApiService.instance.usuarioId ?? 0}';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();

    final lidos = <String, bool>{
      for (final e in _padroes.entries)
        e.key: prefs.getBool(_chave(e.key)) ?? e.value,
    };

    if (!mounted) return;

    setState(() {
      _valores = lidos;
      _carregando = false;
    });
  }

  Future<void> _definir(String nome, bool valor) async {
    setState(() => _valores[nome] = valor);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_chave(nome), valor);
  }

  void _abrirAlterarSenha() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AlterarSenhaSheet(),
    ).then((_) {});
  }

  Future<void> _limparRecentes() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar endereços recentes?'),
        content: const Text(
          'Seus endereços salvos não serão afetados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await EnderecosStore.limparRecentes();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Endereços recentes apagados.')),
    );
  }

  Future<void> _excluirConta() async {
    final excluiu = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ExcluirContaSheet(),
    );

    if (excluiu != true || !mounted) return;

    // A sessão já foi encerrada no ApiService: volta para o login.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _emBreve(String recurso) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$recurso ainda não está disponível.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _preto),
        title: const Text(
          'Configurações',
          style: TextStyle(color: _preto, fontWeight: FontWeight.w700),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: _azul))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                _secao('SEGURANÇA'),
                _acao(
                  Icons.lock_outline_rounded,
                  'Alterar senha',
                  'Troque a senha de acesso da sua conta',
                  _abrirAlterarSenha,
                ),
                _secao('NOTIFICAÇÕES'),
                _interruptor(
                  'notif_status',
                  Icons.notifications_active_outlined,
                  _ehMotorista
                      ? 'Novos chamados'
                      : 'Andamento do atendimento',
                  _ehMotorista
                      ? 'Avisar quando surgir um chamado por perto'
                      : 'Profissional a caminho, no local, concluído',
                ),
                _interruptor(
                  'notif_chat',
                  Icons.chat_bubble_outline_rounded,
                  'Mensagens do chat',
                  'Avisar quando receber uma mensagem',
                ),
                _interruptor(
                  'notif_promocoes',
                  Icons.local_offer_outlined,
                  'Novidades e promoções',
                  'Dicas, novidades e ofertas do Hook',
                ),
                _secao('PRIVACIDADE'),
                _interruptor(
                  'compartilhar_local',
                  Icons.share_location_outlined,
                  'Compartilhar localização no atendimento',
                  'Permite acompanhar a rota em tempo real',
                ),
                if (!_ehMotorista) ...[
                  _interruptor(
                    'confirmar_antes_pedir',
                    Icons.fact_check_outlined,
                    'Revisar antes de pedir ajuda',
                    'Mostrar o resumo do pedido antes de enviar',
                  ),
                  _acao(
                    Icons.history_toggle_off_rounded,
                    'Limpar endereços recentes',
                    'Apaga o histórico de pontos de encontro',
                    _limparRecentes,
                  ),
                ],
                _secao('SOBRE'),
                _acao(
                  Icons.description_outlined,
                  'Termos de uso',
                  null,
                  () => _emBreve('Termos de uso'),
                ),
                _acao(
                  Icons.privacy_tip_outlined,
                  'Política de privacidade',
                  null,
                  () => _emBreve('Política de privacidade'),
                ),
                _acao(
                  Icons.info_outline_rounded,
                  'Versão do app',
                  'Hook 1.0.0 (protótipo)',
                  null,
                ),
                _secao('CONTA'),
                _acaoPerigo(
                  Icons.delete_outline_rounded,
                  'Excluir conta',
                  'Apaga seus dados e encerra o acesso ao app',
                  _excluirConta,
                ),
              ],
            ),
    );
  }

  Widget _secao(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 8),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _cinzaTexto,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _icone(IconData icone) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _azul.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icone, color: _azul, size: 20),
    );
  }

  Widget _acao(
    IconData icone,
    String titulo,
    String? subtitulo,
    VoidCallback? aoTocar,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              _icone(icone),
              const SizedBox(width: 14),
              Expanded(child: _textos(titulo, subtitulo)),
              if (aoTocar != null)
                const Icon(Icons.chevron_right_rounded,
                    color: _cinzaTexto, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _acaoPerigo(
    IconData icone,
    String titulo,
    String subtitulo,
    VoidCallback aoTocar,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _vermelho.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _vermelho.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, color: _vermelho, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _vermelho,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _cinzaTexto,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _vermelho, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _interruptor(
    String chave,
    IconData icone,
    String titulo,
    String subtitulo,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            _icone(icone),
            const SizedBox(width: 14),
            Expanded(child: _textos(titulo, subtitulo)),
            Switch.adaptive(
              value: _valores[chave] ?? false,
              activeColor: _azul,
              onChanged: (v) => _definir(chave, v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textos(String titulo, String? subtitulo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _preto,
          ),
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: const TextStyle(fontSize: 12, color: _cinzaTexto),
          ),
        ],
      ],
    );
  }
}

// ==============================================================
// FOLHA: ALTERAR SENHA (usa o endpoint real atualizar_perfil.php)
// ==============================================================

class _AlterarSenhaSheet extends StatefulWidget {
  const _AlterarSenhaSheet();

  @override
  State<_AlterarSenhaSheet> createState() => _AlterarSenhaSheetState();
}

class _AlterarSenhaSheetState extends State<_AlterarSenhaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _atual = TextEditingController();
  final _nova = TextEditingController();
  final _confirmar = TextEditingController();

  bool _ocultar = true;
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _atual.dispose();
    _nova.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      await ApiService.instance.atualizarPerfil(
        nome: ApiService.instance.nomeUsuario ?? '',
        telefone: ApiService.instance.telefoneUsuario ?? '',
        senhaAtual: _atual.text.trim(),
        novaSenha: _nova.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha alterada com sucesso.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _salvando = false;
        _erro = e.mensagem;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _salvando = false;
        _erro = 'Não foi possível alterar a senha.';
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
        child: Form(
          key: _formKey,
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
              const Text(
                'Alterar senha',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _preto,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _atual,
                obscureText: _ocultar,
                decoration: _campo('Senha atual'),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Informe sua senha atual.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nova,
                obscureText: _ocultar,
                decoration: _campo('Nova senha (mín. 6 caracteres)'),
                validator: (v) => (v == null || v.length < 6)
                    ? 'A nova senha deve ter ao menos 6 caracteres.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmar,
                obscureText: _ocultar,
                decoration: _campo('Confirmar nova senha'),
                validator: (v) =>
                    v != _nova.text ? 'As senhas não coincidem.' : null,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _ocultar = !_ocultar),
                  icon: Icon(
                    _ocultar
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                  label: Text(_ocultar ? 'Mostrar senhas' : 'Ocultar senhas'),
                ),
              ),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _erro!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
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
                          'Alterar senha',
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
// FOLHA: EXCLUIR CONTA (excluir_conta.php)
// ==============================================================

class _ExcluirContaSheet extends StatefulWidget {
  const _ExcluirContaSheet();

  @override
  State<_ExcluirContaSheet> createState() => _ExcluirContaSheetState();
}

class _ExcluirContaSheetState extends State<_ExcluirContaSheet> {
  final _senha = TextEditingController();

  bool _ocultar = true;
  bool _confirmou = false;
  bool _excluindo = false;
  String? _erro;

  @override
  void dispose() {
    _senha.dispose();
    super.dispose();
  }

  Future<void> _excluir() async {
    if (_senha.text.trim().isEmpty) {
      setState(() => _erro = 'Informe sua senha.');

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _excluindo = true;
      _erro = null;
    });

    try {
      await ApiService.instance.excluirConta(senha: _senha.text.trim());

      if (!mounted) return;

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _excluindo = false;
        _erro = e.mensagem;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _excluindo = false;
        _erro = 'Não foi possível excluir a conta agora.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final motorista = ApiService.instance.ehMotorista;

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
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _vermelho.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _vermelho,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'Excluir sua conta?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _preto,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cinzaFundo,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Esta ação não pode ser desfeita. Ao excluir:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _preto,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _item('Seus dados pessoais são apagados'),
                  _item('Você perde o acesso ao app com este e-mail'),
                  _item(
                    motorista
                        ? 'Atendimentos em aberto são cancelados'
                        : 'Pedidos em aberto são cancelados',
                  ),
                  _item(
                    motorista
                        ? 'Seu histórico de atendimentos deixa de ser seu'
                        : 'Seus veículos saem da sua lista',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _senha,
              obscureText: _ocultar,
              enabled: !_excluindo,
              onChanged: (_) {
                if (_erro != null) setState(() => _erro = null);
              },
              decoration: InputDecoration(
                hintText: 'Digite sua senha para confirmar',
                hintStyle: const TextStyle(color: _cinzaTexto),
                filled: true,
                fillColor: _cinzaFundo,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _ocultar
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: _cinzaTexto,
                  ),
                  onPressed: () => setState(() => _ocultar = !_ocultar),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _azul, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _confirmou,
              onChanged: _excluindo
                  ? null
                  : (v) => setState(() => _confirmou = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: _vermelho,
              title: const Text(
                'Entendo que não é possível recuperar a conta.',
                style: TextStyle(fontSize: 13, color: _preto),
              ),
            ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(
                  _erro!,
                  style: const TextStyle(fontSize: 13, color: _vermelho),
                ),
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_confirmou && !_excluindo) ? _excluir : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vermelho,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFDDDDDD),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _excluindo
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Excluir minha conta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed:
                    _excluindo ? null : () => Navigator.pop(context, false),
                child: const Text(
                  'Manter minha conta',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _preto,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5, right: 8),
            child: Icon(Icons.remove_rounded, size: 12, color: _cinzaTexto),
          ),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xFF4A4A4A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
