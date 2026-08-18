import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Ponto único de comunicação com o backend.
/// Todas as telas chamam métodos daqui em vez de usar http diretamente
/// — se a URL do back mudar, ou a forma de autenticar mudar, só mexe
/// aqui.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // ── Troque conforme onde o backend está rodando ──────────
  // Emulador Android:  10.0.2.2   (aponta pro localhost da máquina)
  // iOS Simulator:     localhost
  // Celular físico:    IP da sua máquina na mesma rede Wi-Fi
  //                    (ex: 192.168.0.15) — descubra com `ipconfig`/`ifconfig`
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  String? _token;

  Future<void> _carregarToken() async {
    if (_token != null) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('api_token');
  }

  Future<void> _salvarToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
  }

  Future<bool> get estaLogado async {
    await _carregarToken();
    return _token != null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    if (auth) await _carregarToken();
    final resp = await http.post(
      Uri.parse('$baseUrl/$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _tratarResposta(resp);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    await _carregarToken();
    final resp = await http.get(Uri.parse('$baseUrl/$path'), headers: _headers);
    return _tratarResposta(resp);
  }

  Map<String, dynamic> _tratarResposta(http.Response resp) {
    final dados = resp.body.isNotEmpty
        ? jsonDecode(resp.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (resp.statusCode >= 400) {
      final mensagem = dados['erro'] ??
          dados['messages']?.toString() ??
          'Erro inesperado (${resp.statusCode})';
      throw ApiException(mensagem.toString(), resp.statusCode);
    }
    return dados;
  }

  // ── Autenticação ──────────────────────────────────────────

  Future<Map<String, dynamic>> registro({
    required String nome,
    required String email,
    required String senha,
    required String tipo, // 'cliente' ou 'motorista'
    String? telefone,
  }) async {
    final resp = await _post('auth/registro', {
      'nome': nome,
      'email': email,
      'senha': senha,
      'tipo': tipo,
      if (telefone != null) 'telefone': telefone,
    }, auth: false);
    return resp['usuario'] as Map<String, dynamic>;
  }

  /// Faz login e já salva o token. Retorna os dados do usuário
  /// (inclui `tipo`: 'cliente' ou 'motorista', pra saber pra qual
  /// Home navegar).
  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    final resp = await _post('auth/login', {
      'email': email,
      'senha': senha,
    }, auth: false);
    await _salvarToken(resp['token'] as String);
    return resp['usuario'] as Map<String, dynamic>;
  }

  // ── Veículos ──────────────────────────────────────────────

  Future<List<dynamic>> listarVeiculos() async {
    final resp = await _get('veiculos');
    return resp['veiculos'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> criarVeiculo({
    required String tipo,
    required String marca,
    required String modelo,
    int? ano,
    required String placa,
    String? cor,
  }) async {
    final resp = await _post('veiculos', {
      'tipo': tipo,
      'marca': marca,
      'modelo': modelo,
      if (ano != null) 'ano': ano,
      'placa': placa,
      if (cor != null) 'cor': cor,
    });
    return resp['veiculo'] as Map<String, dynamic>;
  }

  // ── Solicitações — lado cliente ──────────────────────────

  Future<Map<String, dynamic>> criarSolicitacao({
    required int veiculoId,
    required String tipoReboque, // 'Guincho Leve' ou 'Guincho Pesado'
    required String formaPagamento, // 'Pix' ou 'Dinheiro'
    required String endereco,
    required double latitude,
    required double longitude,
  }) async {
    final resp = await _post('solicitacoes', {
      'veiculo_id': veiculoId,
      'tipo_reboque': tipoReboque,
      'forma_pagamento': formaPagamento,
      'endereco': endereco,
      'latitude': latitude,
      'longitude': longitude,
    });
    return resp['solicitacao'] as Map<String, dynamic>;
  }

  /// Usado pro polling na tela de rastreio. Retorna a solicitação
  /// atualizada, a mensagem amigável de status, e os dados do
  /// motorista quando já tiver um atribuído.
  Future<Map<String, dynamic>> consultarSolicitacao(int id) {
    return _get('solicitacoes/$id');
  }

  Future<List<dynamic>> minhasSolicitacoes() async {
    final resp = await _get('solicitacoes/minhas');
    return resp['solicitacoes'] as List<dynamic>;
  }

  Future<void> cancelarSolicitacao(int id) {
    return _post('solicitacoes/$id/cancelar', {});
  }

  // ── Solicitações — lado motorista ────────────────────────

  Future<List<dynamic>> solicitacoesDisponiveis() async {
    final resp = await _get('solicitacoes/disponiveis');
    return resp['solicitacoes'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> aceitarSolicitacao(int id) async {
    final resp = await _post('solicitacoes/$id/aceitar', {});
    return resp['solicitacao'] as Map<String, dynamic>;
  }

  Future<void> atualizarStatus(int id, String status) {
    // status: 'a_caminho' | 'concluido' | 'cancelado'
    return _post('solicitacoes/$id/status', {'status': status});
  }

  // ── Avaliação ─────────────────────────────────────────────

  Future<void> avaliar({required int solicitacaoId, required int nota}) {
    return _post('avaliacoes', {
      'solicitacao_id': solicitacaoId,
      'nota': nota,
    });
  }
}

class ApiException implements Exception {
  final String mensagem;
  final int statusCode;
  ApiException(this.mensagem, this.statusCode);

  @override
  String toString() => mensagem;
}
