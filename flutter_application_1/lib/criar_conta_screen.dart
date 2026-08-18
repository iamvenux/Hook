import 'package:flutter/material.dart';
import 'home.dart';

// ─────────────────────────────────────────────
//  Dados de domínio
// ─────────────────────────────────────────────
enum TipoPerfil { usuario, socorrista }

enum TipoAtuacao { autonomo, empresa, pessoa }

const List<String> kServicosDisponiveis = [
  'Troca de pneu',
  'Recarga de bateria',
  'Abastecimento de emergência',
  'Chaveiro automotivo',
  'Mecânico leve',
  'Empurrar veículo',
  'Primeiros socorros básicos',
  'Orientação de rota',
];

// ─────────────────────────────────────────────
//  Widget principal
// ─────────────────────────────────────────────
class CriarContaScreen extends StatefulWidget {
  const CriarContaScreen({super.key});

  @override
  State<CriarContaScreen> createState() => _CriarContaScreenState();
}

class _CriarContaScreenState extends State<CriarContaScreen> {
  // ── Cores ──────────────────────────────────
  static const Color azulPrincipal  = Color(0xFF1A7EF5);
  static const Color cinzaTexto     = Color(0xFF8A8A8A);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaBorda     = Color(0xFFDDDDDD);
  static const Color cinzaFundo     = Color(0xFFF5F5F5);

  // ── Etapa ──────────────────────────────────
  // 0 = seleção de perfil | 1 = formulário
  int _etapa = 0;

  // ── Perfil selecionado ─────────────────────
  TipoPerfil? _perfil;
  TipoAtuacao _tipoAtuacao = TipoAtuacao.autonomo;
  final Set<String> _servicosSelecionados = {};

  // ── Controllers ────────────────────────────
  final _formKey                  = GlobalKey<FormState>();
  final _nomeController           = TextEditingController();
  final _emailController          = TextEditingController();
  final _telefoneController       = TextEditingController();
  final _cpfCnpjController        = TextEditingController();
  final _senhaController          = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _senhaVisivel          = false;
  bool _confirmarSenhaVisivel = false;
  bool _carregando            = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cpfCnpjController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  // ── Ações ──────────────────────────────────
  void _confirmarPerfil() {
    if (_perfil == null) return;
    setState(() => _etapa = 1);
  }

  Future<void> _criarConta() async {
    if (!_formKey.currentState!.validate()) return;

    if (_perfil == TipoPerfil.socorrista && _servicosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um serviço oferecido.')),
      );
      return;
    }

    setState(() => _carregando = true);
    await Future.delayed(const Duration(seconds: 2)); // TODO: API
    setState(() => _carregando = false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  // ─────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            if (_etapa == 1) {
              setState(() => _etapa = 0);
            } else {
              Navigator.pop(context);
            }
          },
          child: const Icon(Icons.arrow_back, color: pretoPrincipal),
        ),
      ),
      body: SafeArea(
        child: _etapa == 0 ? _buildSelecaoPerfil() : _buildFormulario(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Etapa 0 — Seleção de perfil
  // ─────────────────────────────────────────────
  Widget _buildSelecaoPerfil() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
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
            'Como você vai usar o Hook?',
            style: TextStyle(fontSize: 15, color: cinzaTexto),
          ),
          const SizedBox(height: 40),

          // Card Usuário
          _buildPerfilCard(
            perfil: TipoPerfil.usuario,
            icon: Icons.person_outline_rounded,
            titulo: 'Usuário',
            descricao: 'Preciso de socorro em estrada ou ajuda com meu veículo.',
          ),

          const SizedBox(height: 16),

          // Card Socorrista
          _buildPerfilCard(
            perfil: TipoPerfil.socorrista,
            icon: Icons.build_outlined,
            titulo: 'Motorista Socorrista',
            descricao: 'Quero oferecer serviços de auxílio em rodovias.',
          ),

          const Spacer(),

          // Botão continuar
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _perfil != null ? _confirmarPerfil : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: azulPrincipal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: azulPrincipal.withOpacity(0.35),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 24),

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
    );
  }

  Widget _buildPerfilCard({
    required TipoPerfil perfil,
    required IconData icon,
    required String titulo,
    required String descricao,
  }) {
    final selecionado = _perfil == perfil;

    return GestureDetector(
      onTap: () => setState(() => _perfil = perfil),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selecionado ? azulPrincipal.withOpacity(0.06) : cinzaFundo,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selecionado ? azulPrincipal : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selecionado
                    ? azulPrincipal.withOpacity(0.12)
                    : const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: selecionado ? azulPrincipal : cinzaTexto, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color:
                          selecionado ? azulPrincipal : pretoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descricao,
                    style: const TextStyle(fontSize: 13, color: cinzaTexto),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selecionado ? azulPrincipal : cinzaBorda,
                  width: 2,
                ),
                color: selecionado ? azulPrincipal : Colors.transparent,
              ),
              child: selecionado
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Etapa 1 — Formulário
  // ─────────────────────────────────────────────
  Widget _buildFormulario() {
    final isSocorrista = _perfil == TipoPerfil.socorrista;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Badge de perfil
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: azulPrincipal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSocorrista
                        ? Icons.build_outlined
                        : Icons.person_outline_rounded,
                    color: azulPrincipal,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isSocorrista ? 'Motorista Socorrista' : 'Usuário',
                    style: const TextStyle(
                      fontSize: 13,
                      color: azulPrincipal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

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

            // ── Dados básicos ──────────────────
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

            // ── Campos extras — apenas socorrista ──
            if (isSocorrista) ...[
              const SizedBox(height: 32),
              _buildSectionDivider('Dados profissionais'),
              const SizedBox(height: 20),

              // Tipo de atuação
              _buildLabel('Tipo de atuação'),
              const SizedBox(height: 12),
              _buildTipoAtuacao(),

              const SizedBox(height: 20),

              // CPF / CNPJ dinâmico
              _buildLabel(
                  _tipoAtuacao == TipoAtuacao.empresa ? 'CNPJ' : 'CPF'),
              const SizedBox(height: 8),
              _buildInput(
                controller: _cpfCnpjController,
                hint: _tipoAtuacao == TipoAtuacao.empresa
                    ? '00.000.000/0001-00'
                    : '000.000.000-00',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return _tipoAtuacao == TipoAtuacao.empresa
                        ? 'Informe o CNPJ'
                        : 'Informe o CPF';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Serviços oferecidos
              _buildLabel('Serviços oferecidos'),
              const SizedBox(height: 4),
              const Text(
                'Selecione todos os serviços que você pode prestar',
                style: TextStyle(fontSize: 13, color: cinzaTexto),
              ),
              const SizedBox(height: 12),
              _buildServicosGrid(),
            ],

            // ── Senha ──────────────────────────
            const SizedBox(height: 32),
            if (isSocorrista) _buildSectionDivider('Segurança'),
            if (isSocorrista) const SizedBox(height: 20),

            _buildLabel('Senha'),
            const SizedBox(height: 8),
            _buildInputSenha(
              controller: _senhaController,
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

            _buildLabel('Confirmar senha'),
            const SizedBox(height: 8),
            _buildInputSenha(
              controller: _confirmarSenhaController,
              visivel: _confirmarSenhaVisivel,
              onToggle: () => setState(
                  () => _confirmarSenhaVisivel = !_confirmarSenhaVisivel),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirme sua senha';
                if (v != _senhaController.text)
                  return 'As senhas não coincidem';
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

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ─── Tipo de atuação (pills) ───────────────
  Widget _buildTipoAtuacao() {
    const opcoes = [
      (TipoAtuacao.autonomo, 'Autônomo'),
      (TipoAtuacao.empresa,  'Empresa'),
      (TipoAtuacao.pessoa,   'Pessoa disponível'),
    ];

    return Row(
      children: opcoes.map((op) {
        final (tipo, label) = op;
        final ativo = _tipoAtuacao == tipo;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() {
              _tipoAtuacao = tipo;
              _cpfCnpjController.clear();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: ativo ? azulPrincipal : cinzaFundo,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: ativo ? azulPrincipal : cinzaBorda,
                  width: 1.5,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ativo ? Colors.white : cinzaTexto,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Grid de serviços ──────────────────────
  Widget _buildServicosGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kServicosDisponiveis.map((servico) {
        final selecionado = _servicosSelecionados.contains(servico);
        return GestureDetector(
          onTap: () => setState(() {
            if (selecionado) {
              _servicosSelecionados.remove(servico);
            } else {
              _servicosSelecionados.add(servico);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selecionado
                  ? azulPrincipal.withOpacity(0.1)
                  : cinzaFundo,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: selecionado ? azulPrincipal : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selecionado) ...[
                  const Icon(Icons.check_circle_rounded,
                      color: azulPrincipal, size: 15),
                  const SizedBox(width: 5),
                ],
                Text(
                  servico,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selecionado ? azulPrincipal : cinzaTexto,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Divisor de seção ─────────────────────
  Widget _buildSectionDivider(String titulo) {
    return Row(
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cinzaTexto,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: Color(0xFFEEEEEE), thickness: 1)),
      ],
    );
  }

  // ─── Helpers de input ─────────────────────
  Widget _buildLabel(String texto) => Text(
        texto,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: pretoPrincipal),
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
          borderSide: const BorderSide(color: cinzaBorda, width: 1.5),
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
        hintText: '••••••••',
        hintStyle: const TextStyle(color: cinzaTexto, fontSize: 18),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(
            visivel
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: cinzaTexto,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cinzaBorda, width: 1.5),
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