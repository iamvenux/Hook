import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String mensagem;
  final int? statusCode;

  ApiException(
    this.mensagem, {
    this.statusCode,
  });

  @override
  String toString() => mensagem;
}

class ApiService {
  ApiService._();

  static final ApiService instance =
      ApiService._();

  // ============================================================
  // URL
  // ============================================================

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/flutter_application_1/backend/api';
    }

    return 'http://10.0.2.2/flutter_application_1/backend/api';
  }

  // ============================================================
  // USUÁRIO LOGADO
  // ============================================================

  int? _usuarioId;

  String? _nomeUsuario;
  String? _emailUsuario;
  String? _tipoUsuario;
  String? _telefoneUsuario;
  String? _placaGuincho;
  String? _apiToken;

  int? get usuarioId =>
      _usuarioId;

  String? get nomeUsuario =>
      _nomeUsuario;

  String? get emailUsuario =>
      _emailUsuario;

  String? get tipoUsuario =>
      _tipoUsuario;

  String? get telefoneUsuario =>
      _telefoneUsuario;

  String? get placaGuincho =>
      _placaGuincho;

  String? get apiToken =>
      _apiToken;

  bool get estaLogado =>
      _usuarioId != null;

  bool get ehCliente =>
      _tipoUsuario == 'cliente';

  bool get ehMotorista =>
      _tipoUsuario == 'motorista';

  // ============================================================
  // LOGIN
  // ============================================================

  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/login.php',
          ),
          headers: {
            'Content-Type':
                'application/json',
            'Accept':
                'application/json',
          },
          body: jsonEncode({
            'email': email,
            'senha': senha,
          }),
        )
        .timeout(
          const Duration(
            seconds: 10,
          ),
        );

    final dados =
        await _decodificarResposta(
      response,
    );

    final usuarioRaw =
        dados['usuario'];

    if (usuarioRaw is! Map) {
      throw ApiException(
        'O servidor não retornou os dados do usuário.',
      );
    }

    final usuario =
        Map<String, dynamic>.from(
      usuarioRaw,
    );

    final id =
        _paraInt(
      usuario['id'],
    );

    if (id == null) {
      throw ApiException(
        'Usuário inválido.',
      );
    }

    _usuarioId = id;

    _nomeUsuario =
        usuario['nome']?.toString();

    _emailUsuario =
        usuario['email']?.toString();

    _tipoUsuario =
        usuario['tipo']?.toString();

    _telefoneUsuario =
        usuario['telefone']?.toString();

    _placaGuincho =
        usuario['placa_guincho']
            ?.toString();

    _apiToken =
        usuario['api_token']
            ?.toString();

    return usuario;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void logout() {
    _usuarioId = null;

    _nomeUsuario = null;

    _emailUsuario = null;

    _tipoUsuario = null;

    _telefoneUsuario = null;

    _placaGuincho = null;

    _apiToken = null;
  }

  // ============================================================
  // ADICIONAR VEÍCULO
  // ============================================================

  Future<Map<String, dynamic>>
      adicionarVeiculo({
    required String tipo,
    required String marca,
    required String modelo,
    required int ano,
    required String placa,
    required String cor,
  }) async {
    final id =
        _usuarioId;

    if (id == null) {
      throw ApiException(
        'Usuário não identificado. Faça login novamente.',
      );
    }

    if (_tipoUsuario !=
        'cliente') {
      throw ApiException(
        'Somente clientes podem cadastrar veículos.',
      );
    }

    final response =
        await http
            .post(
              Uri.parse(
                '$baseUrl/adicionar_veiculo.php',
              ),
              headers: {
                'Content-Type':
                    'application/json',
                'Accept':
                    'application/json',
              },
              body: jsonEncode({
                'usuario_id':
                    id,
                'tipo':
                    tipo,
                'marca':
                    marca,
                'modelo':
                    modelo,
                'ano':
                    ano,
                'placa':
                    placa,
                'cor':
                    cor,
              }),
            )
            .timeout(
              const Duration(
                seconds: 10,
              ),
            );

    return _decodificarResposta(
      response,
    );
  }

  // ============================================================
  // LISTAR VEÍCULOS
  // ============================================================

  Future<List<Map<String, dynamic>>>
      listarVeiculos() async {
    final id =
        _usuarioId;

    if (id == null) {
      throw ApiException(
        'Usuário não identificado. Faça login novamente.',
      );
    }

    if (_tipoUsuario !=
        'cliente') {
      throw ApiException(
        'Somente clientes possuem veículos cadastrados.',
      );
    }

    final uri =
        Uri.parse(
      '$baseUrl/listar_veiculos.php'
      '?usuario_id=$id',
    );

    final response =
        await http
            .get(
              uri,
              headers: const {
                'Accept':
                    'application/json',
              },
            )
            .timeout(
              const Duration(
                seconds: 5,
              ),
            );

    final dados =
        await _decodificarResposta(
      response,
    );

    final lista =
        dados['veiculos'];

    if (lista is! List) {
      return [];
    }

    return lista
        .map(
          (item) =>
              Map<String, dynamic>.from(
            item as Map,
          ),
        )
        .toList();
  }

  // ============================================================
  // CRIAR SOLICITAÇÃO
  // ============================================================

  Future<Map<String, dynamic>>
      criarSolicitacao({
    required int veiculoId,
    required String tipoReboque,
    required String formaPagamento,
    required String endereco,
    required double latitude,
    required double longitude,
    double? valorEstimado,
  }) async {
    final clienteId =
        _usuarioId;

    if (clienteId == null) {
      throw ApiException(
        'Cliente não identificado.',
      );
    }

    final body =
        <String, dynamic>{
      'cliente_id':
          clienteId,
      'veiculo_id':
          veiculoId,
      'tipo_reboque':
          tipoReboque,
      'forma_pagamento':
          formaPagamento,
      'endereco':
          endereco,
      'latitude':
          latitude,
      'longitude':
          longitude,
    };

    if (valorEstimado != null) {
      body['valor_estimado'] =
          valorEstimado;
    }

    final response =
        await http
            .post(
              Uri.parse(
                '$baseUrl/criar_solicitacao.php',
              ),
              headers: {
                'Content-Type':
                    'application/json',
                'Accept':
                    'application/json',
              },
              body:
                  jsonEncode(
                body,
              ),
            )
            .timeout(
              const Duration(
                seconds: 10,
              ),
            );

    return _decodificarResposta(
      response,
    );
  }

  // ============================================================
  // CONSULTAR SOLICITAÇÃO
  // ============================================================

  Future<Map<String, dynamic>>
      consultarSolicitacao(
    int solicitacaoId,
  ) async {
    final uri =
        Uri.parse(
      '$baseUrl/consultar_solicitacao.php'
      '?solicitacao_id=$solicitacaoId',
    );

    final response =
        await http
            .get(
              uri,
              headers: const {
                'Accept':
                    'application/json',
              },
            )
            .timeout(
              const Duration(
                seconds: 5,
              ),
            );

    return _decodificarResposta(
      response,
    );
  }

  // ============================================================
  // CANCELAR
  // ============================================================

  Future<Map<String, dynamic>>
      cancelarSolicitacao(
    int solicitacaoId,
  ) async {
    final response =
        await http
            .post(
              Uri.parse(
                '$baseUrl/cancelar_solicitacao.php',
              ),
              headers: {
                'Content-Type':
                    'application/json',
                'Accept':
                    'application/json',
              },
              body:
                  jsonEncode({
                'solicitacao_id':
                    solicitacaoId,
                if (_usuarioId != null)
                  'cliente_id':
                      _usuarioId,
              }),
            )
            .timeout(
              const Duration(
                seconds: 10,
              ),
            );

    return _decodificarResposta(
      response,
    );
  }

  // ============================================================
  // BUSCAR SOLICITAÇÕES - MOTORISTA
  // ============================================================

  Future<List<Map<String, dynamic>>>
      buscarSolicitacoes({
    int? motoristaId,
  }) async {
    final id =
        motoristaId ??
            _usuarioId;

    if (id == null) {
      throw ApiException(
        'Motorista não identificado.',
      );
    }

    final uri =
        Uri.parse(
      '$baseUrl/buscar_solicitacoes.php'
      '?motorista_id=$id',
    );

    final response =
        await http
            .get(
              uri,
              headers: const {
                'Accept':
                    'application/json',
              },
            )
            .timeout(
              const Duration(
                seconds: 5,
              ),
            );

    final dados =
        await _decodificarResposta(
      response,
    );

    final lista =
        dados['solicitacoes'];

    if (lista is! List) {
      return [];
    }

    return lista
        .map(
          (item) =>
              Map<String, dynamic>.from(
            item as Map,
          ),
        )
        .toList();
  }

  // ============================================================
  // ACEITAR SOLICITAÇÃO
  // ============================================================

  Future<Map<String, dynamic>>
      aceitarSolicitacao({
    required int solicitacaoId,
    int? motoristaId,
  }) async {
    final id =
        motoristaId ??
            _usuarioId;

    if (id == null) {
      throw ApiException(
        'Motorista não identificado.',
      );
    }

    final response =
        await http
            .post(
              Uri.parse(
                '$baseUrl/aceitar_solicitacao.php',
              ),
              headers: {
                'Content-Type':
                    'application/json',
                'Accept':
                    'application/json',
              },
              body:
                  jsonEncode({
                'solicitacao_id':
                    solicitacaoId,
                'motorista_id':
                    id,
              }),
            )
            .timeout(
              const Duration(
                seconds: 10,
              ),
            );

    return _decodificarResposta(
      response,
    );
  }

  // ============================================================
  // ATUALIZAR STATUS
  // ============================================================

  Future<Map<String, dynamic>>
      atualizarStatus({
    required int solicitacaoId,
    required String status,
    int? motoristaId,
  }) async {
    final id =
        motoristaId ??
            _usuarioId;

    if (id == null) {
      throw ApiException(
        'Motorista não identificado.',
      );
    }

    final response =
        await http
            .post(
              Uri.parse(
                '$baseUrl/atualizar_status.php',
              ),
              headers: {
                'Content-Type':
                    'application/json',
                'Accept':
                    'application/json',
              },
              body:
                  jsonEncode({
                'solicitacao_id':
                    solicitacaoId,
                'motorista_id':
                    id,
                'status':
                    status,
              }),
            )
            .timeout(
              const Duration(
                seconds: 10,
              ),
            );

    return _decodificarResposta(
      response,
    );
  }

  // ============================================================
  // LOCALIZAÇÃO
  // ============================================================

  Future<Map<String, dynamic>>
      atualizarLocalizacao({
    required double latitude,
    required double longitude,
    int? motoristaId,
  }) async {
    final id =
        motoristaId ??
            _usuarioId;

    if (id == null) {
      throw ApiException(
        'Motorista não identificado.',
      );
    }

    final response =
        await http
            .post(
              Uri.parse(
                '$baseUrl/atualizar_localizacao.php',
              ),
              headers: {
                'Content-Type':
                    'application/json',
                'Accept':
                    'application/json',
              },
              body:
                  jsonEncode({
                'motorista_id':
                    id,
                'latitude':
                    latitude,
                'longitude':
                    longitude,
              }),
            )
            .timeout(
              const Duration(
                seconds: 5,
              ),
            );

    return _decodificarResposta(
      response,
    );
  }

  // ============================================================
  // DISPONIBILIDADE
  // ============================================================

  Future<Map<String, dynamic>>
      atualizarDisponibilidade({
    required bool disponivel,
    int? motoristaId,
  }) async {
    final id =
        motoristaId ??
            _usuarioId;

    if (id == null) {
      throw ApiException(
        'Motorista não identificado.',
      );
    }

    final response =
        await http
            .post(
              Uri.parse(
                '$baseUrl/atualizar_disponibilidade.php',
              ),
              headers: {
                'Content-Type':
                    'application/json',
                'Accept':
                    'application/json',
              },
              body:
                  jsonEncode({
                'motorista_id':
                    id,
                'disponivel':
                    disponivel
                        ? 1
                        : 0,
              }),
            )
            .timeout(
              const Duration(
                seconds: 5,
              ),
            );

    return _decodificarResposta(
      response,
    );
  }

  // ============================================================
  // RESPOSTA
  // ============================================================

  Future<Map<String, dynamic>>
      _decodificarResposta(
    http.Response response,
  ) async {
    Map<String, dynamic>
        dados;

    try {
      final decoded =
          jsonDecode(
        response.body,
      );

      if (decoded is! Map) {
        throw const FormatException();
      }

      dados =
          Map<String, dynamic>.from(
        decoded,
      );
    } catch (_) {
      throw ApiException(
        'Resposta inválida do servidor: ${response.body}',
        statusCode:
            response.statusCode,
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw ApiException(
        dados['mensagem']
                ?.toString() ??
            'Erro do servidor.',
        statusCode:
            response.statusCode,
      );
    }

    if (dados['sucesso'] ==
        false) {
      throw ApiException(
        dados['mensagem']
                ?.toString() ??
            'Não foi possível realizar a operação.',
        statusCode:
            response.statusCode,
      );
    }

    return dados;
  }

  int? _paraInt(
    dynamic valor,
  ) {
    if (valor == null) {
      return null;
    }

    if (valor is int) {
      return valor;
    }

    return int.tryParse(
      valor.toString(),
    );
  }
}