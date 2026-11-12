import 'package:flutter_application_1/services/api_service.dart';

/// Regras de acesso: login, cadastro, confirmação de e-mail,
/// recuperação de senha e dados do usuário logado.
class AuthController {
  AuthController._();

  static final AuthController instance = AuthController._();

  final ApiService _api = ApiService.instance;

  // ============================================================
  // USUÁRIO LOGADO
  // ============================================================

  String? get nomeUsuario => _api.nomeUsuario;

  String? get emailUsuario => _api.emailUsuario;

  String? get telefoneUsuario => _api.telefoneUsuario;

  String? get tipoUsuario => _api.tipoUsuario;

  String? get placaGuincho => _api.placaGuincho;

  /// `Leve` ou `Pesado` (só para motorista).
  String? get tipoGuincho => _api.tipoGuincho;

  /// `Pix` ou `Dinheiro`; vem marcada ao solicitar um serviço.
  String get formaPagamentoPadrao {
    final forma = _api.formaPagamentoPadrao;
    return forma == 'Dinheiro' ? 'Dinheiro' : 'Pix';
  }

  bool get estaLogado => _api.estaLogado;

  bool get ehCliente => _api.ehCliente;

  bool get ehMotorista => _api.ehMotorista;

  // ============================================================
  // LOGIN / LOGOUT
  // ============================================================

  /// Faz o login e devolve os dados do usuário.
  /// O campo `tipo` vem como `cliente` ou `motorista`.
  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) {
    return _api.login(
      email: email,
      senha: senha,
    );
  }

  /// Apaga os dados do usuário logado guardados em memória.
  void logout() {
    _api.logout();
  }

  // ============================================================
  // PERFIL
  // ============================================================

  /// Atualiza os dados do usuário logado. Os getters acima já
  /// refletem os novos valores depois que a chamada termina.
  Future<Map<String, dynamic>> atualizarPerfil({
    required String nome,
    required String telefone,
    String? placaGuincho,
    String? tipoGuincho,
  }) {
    return _api.atualizarPerfil(
      nome: nome,
      telefone: telefone,
      placaGuincho: placaGuincho,
      tipoGuincho: tipoGuincho,
    );
  }

  Future<Map<String, dynamic>> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) {
    return _api.alterarSenha(
      senhaAtual: senhaAtual,
      novaSenha: novaSenha,
    );
  }

  Future<Map<String, dynamic>> atualizarFormaPagamento(
    String formaPagamento,
  ) {
    return _api.atualizarFormaPagamento(formaPagamento);
  }

  /// Exclui a conta e limpa a sessão. Depois disso o app deve
  /// voltar para a tela de login.
  Future<Map<String, dynamic>> excluirConta({
    required String senha,
  }) {
    return _api.excluirConta(senha: senha);
  }

  // ============================================================
  // CADASTRO / VERIFICAÇÃO DE E-MAIL
  // ============================================================

  Future<Map<String, dynamic>> criarConta({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required String tipo,
    String? placaGuincho,
    String? tipoGuincho,
  }) {
    return _api.criarConta(
      nome: nome,
      email: email,
      telefone: telefone,
      senha: senha,
      tipo: tipo,
      placaGuincho: placaGuincho,
      tipoGuincho: tipoGuincho,
    );
  }

  Future<Map<String, dynamic>> verificarEmail({
    required String email,
    required String codigo,
  }) {
    return _api.verificarEmail(
      email: email,
      codigo: codigo,
    );
  }

  Future<Map<String, dynamic>> reenviarCodigoVerificacao({
    required String email,
  }) {
    return _api.reenviarCodigoVerificacao(
      email: email,
    );
  }

  // ============================================================
  // RECUPERAÇÃO DE SENHA
  // ============================================================

  Future<Map<String, dynamic>> solicitarRecuperacaoSenha({
    required String email,
  }) {
    return _api.solicitarRecuperacaoSenha(
      email: email,
    );
  }

  Future<Map<String, dynamic>> validarCodigoRecuperacao({
    required String email,
    required String codigo,
  }) {
    return _api.validarCodigoRecuperacao(
      email: email,
      codigo: codigo,
    );
  }

  Future<Map<String, dynamic>> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) {
    return _api.redefinirSenha(
      email: email,
      codigo: codigo,
      novaSenha: novaSenha,
    );
  }
}
