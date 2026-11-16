import 'dart:convert';
import 'dart:typed_data';

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

    // Celular físico
    return 'http://192.168.0.7/flutter_application_1/backend/api';
  }

  // ============================================================
  // USUÁRIO LOGADO
  // ============================================================

  int? _usuarioId;

  String? _nomeUsuario;
  String? _emailUsuario;
  String? _tipoUsuario;
  String? _telefoneUsuario;
  String? _fotoUsuario;
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

  /// Caminho relativo da foto de perfil (ex.: uploads/perfil/u1_ab12.jpg).
  String? get fotoUsuario => _fotoUsuario;

  /// Monta a URL completa de uma foto guardada no servidor.
  /// Retorna null quando não há foto.
  static String? urlFoto(String? relativo) {
    if (relativo == null || relativo.trim().isEmpty) return null;

    if (relativo.startsWith('http')) return relativo;

    final base = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

    return '$base/$relativo';
  }

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

    _fotoUsuario =
        usuario['foto_url']?.toString();

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

    _fotoUsuario = null;

    _placaGuincho = null;

    _apiToken = null;
  }

  // ============================================================
  // ATUALIZAR PERFIL
  // ============================================================

  /// Atualiza nome/telefone do usuário logado e, opcionalmente,
  /// a senha (quando [senhaAtual] e [novaSenha] forem informadas).
  Future<Map<String, dynamic>> atualizarPerfil({
    required String nome,
    required String telefone,
    String? senhaAtual,
    String? novaSenha,
    String? email,
  }) async {
    final id = _usuarioId;

    if (id == null) {
      throw ApiException(
        'Usuário não identificado. Faça login novamente.',
      );
    }

    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/atualizar_perfil.php',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'usuario_id': id,
            'nome': nome,
            'telefone': telefone,
            if (senhaAtual != null && senhaAtual.isNotEmpty)
              'senha_atual': senhaAtual,
            if (novaSenha != null && novaSenha.isNotEmpty)
              'nova_senha': novaSenha,
            if (email != null && email.isNotEmpty) 'email': email,
          }),
        )
        .timeout(
          const Duration(seconds: 10),
        );

    final dados = await _decodificarResposta(response);

    // Atualiza a sessão em memória com os novos dados,
    // pra refletir na UI sem precisar relogar.
    // Usa o que o banco realmente gravou (telefone só com dígitos,
    // e-mail em minúsculas); se a resposta não trouxer, cai no enviado.
    final salvo = dados['usuario'];

    _nomeUsuario = (salvo is Map && salvo['nome'] != null)
        ? salvo['nome'].toString()
        : nome;

    _telefoneUsuario = (salvo is Map && salvo['telefone'] != null)
        ? salvo['telefone'].toString()
        : telefone;

    if (salvo is Map &&
        salvo['email'] != null &&
        salvo['email'].toString().isNotEmpty) {
      _emailUsuario = salvo['email'].toString();
    } else if (email != null && email.isNotEmpty) {
      _emailUsuario = email.toLowerCase();
    }

    return dados;
  }

  // ============================================================
  // TROCA DE E-MAIL COM CÓDIGO (enviado ao NOVO e-mail)
  // ============================================================

  Future<Map<String, dynamic>> solicitarTrocaEmail(
    String novoEmail,
  ) async {
    final id = _usuarioId;

    if (id == null) {
      throw ApiException(
        'Usuário não identificado. Faça login novamente.',
      );
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/solicitar_troca_email.php'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'usuario_id': id,
            'novo_email': novoEmail.trim(),
          }),
        )
        .timeout(const Duration(seconds: 25));

    return _decodificarResposta(response);
  }

  Future<Map<String, dynamic>> confirmarTrocaEmail(
    String codigo,
  ) async {
    final id = _usuarioId;

    if (id == null) {
      throw ApiException(
        'Usuário não identificado. Faça login novamente.',
      );
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/confirmar_troca_email.php'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'usuario_id': id,
            'codigo': codigo.trim(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    final dados = await _decodificarResposta(response);

    final usuario = dados['usuario'];

    if (usuario is Map && usuario['email'] != null) {
      _emailUsuario = usuario['email'].toString();
    }

    return dados;
  }

  // ============================================================
  // FOTO DE PERFIL
  // ============================================================

  /// Envia a foto (bytes + nome do arquivo) e guarda o caminho novo.
  Future<String?> enviarFotoPerfil(
    Uint8List bytes,
    String nomeArquivo,
  ) async {
    final id = _usuarioId;

    if (id == null) {
      throw ApiException(
        'Usuário não identificado. Faça login novamente.',
      );
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/enviar_foto_perfil.php'),
    )
      ..fields['usuario_id'] = id.toString()
      ..files.add(
        http.MultipartFile.fromBytes(
          'foto',
          bytes,
          filename: nomeArquivo,
        ),
      );

    final streamed = await request.send().timeout(
          const Duration(seconds: 40),
        );

    final response = await http.Response.fromStream(streamed);

    final dados = await _decodificarResposta(response);

    _fotoUsuario = dados['foto_url']?.toString();

    return _fotoUsuario;
  }

  Future<void> removerFotoPerfil() async {
    final id = _usuarioId;

    if (id == null) {
      throw ApiException(
        'Usuário não identificado. Faça login novamente.',
      );
    }

    final response = await http.post(
      Uri.parse('$baseUrl/enviar_foto_perfil.php'),
      body: {
        'usuario_id': id.toString(),
        'remover': '1',
      },
    ).timeout(const Duration(seconds: 15));

    await _decodificarResposta(response);

    _fotoUsuario = null;
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

  // NOVOS
  bool precisaTroco = false,
  double? trocoPara,
}) async {
  final clienteId =
      _usuarioId;

  if (clienteId == null) {
    throw ApiException(
      'Cliente não identificado.',
    );
  }

  if (_tipoUsuario != 'cliente') {
    throw ApiException(
      'Somente clientes podem criar solicitações.',
    );
  }

  // ============================================================
  // NORMALIZA TROCO
  // ============================================================

  bool precisaTrocoFinal =
      precisaTroco;

  double? trocoParaFinal =
      trocoPara;

  if (formaPagamento != 'Dinheiro') {
    precisaTrocoFinal = false;
    trocoParaFinal = null;
  }

  if (
      formaPagamento == 'Dinheiro' &&
      !precisaTrocoFinal) {
    trocoParaFinal = null;
  }

  if (
      formaPagamento == 'Dinheiro' &&
      precisaTrocoFinal &&
      (trocoParaFinal == null ||
          trocoParaFinal <= 0)) {
    throw ApiException(
      'Informe para quanto precisa de troco.',
    );
  }

  // ============================================================
  // BODY
  // ============================================================

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

    'precisa_troco':
        precisaTrocoFinal
            ? 1
            : 0,

    'troco_para':
        trocoParaFinal,

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
// CADASTRO / VERIFICAÇÃO DE E-MAIL
// Cole estes métodos DENTRO da classe ApiService.
// ============================================================

Future<Map<String, dynamic>> criarConta({
  required String nome,
  required String email,
  required String telefone,
  required String senha,
  required String tipo,
  String? placaGuincho,
  String? tipoGuincho,
}) async {
  final response = await http
      .post(
        Uri.parse(
          '$baseUrl/criar_conta.php',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nome': nome,
          'email': email,
          'telefone': telefone,
          'senha': senha,
          'tipo': tipo,
          'placa_guincho': placaGuincho,
          'tipo_guincho': tipoGuincho,
        }),
      )
      .timeout(
        const Duration(seconds: 15),
      );

  return _decodificarResposta(
    response,
  );
}

Future<Map<String, dynamic>> verificarEmail({
  required String email,
  required String codigo,
}) async {
  final response = await http
      .post(
        Uri.parse(
          '$baseUrl/verificar_email.php',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'codigo': codigo,
        }),
      )
      .timeout(
        const Duration(seconds: 10),
      );

  return _decodificarResposta(
    response,
  );
}

Future<Map<String, dynamic>>
    reenviarCodigoVerificacao({
  required String email,
}) async {
  final response = await http
      .post(
        Uri.parse(
          '$baseUrl/reenviar_codigo_verificacao.php',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      )
      .timeout(
        const Duration(seconds: 15),
      );

  return _decodificarResposta(
    response,
  );
}


  // ============================================================
  // SOLICITAR RECUPERAÇÃO DE SENHA
  // ============================================================

  Future<Map<String, dynamic>> solicitarRecuperacaoSenha({
    required String email,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/solicitar_recuperacao_senha.php',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': email,
          }),
        )
        .timeout(
          const Duration(
            seconds: 15,
          ),
        );

    return _decodificarResposta(
      response,
    );
  }

  // ============================================================
  // VALIDAR CÓDIGO DE RECUPERAÇÃO
  // ============================================================

  Future<Map<String, dynamic>> validarCodigoRecuperacao({
    required String email,
    required String codigo,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/validar_codigo_recuperacao.php',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'codigo': codigo,
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
  // REDEFINIR SENHA
  // ============================================================

  Future<Map<String, dynamic>> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/redefinir_senha.php',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'codigo': codigo,
            'nova_senha': novaSenha,
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
  // CHAT DA SOLICITAÇÃO
  // ============================================================

  Future<List<Map<String, dynamic>>> listarMensagens(
    int solicitacaoId,
  ) async {
    final usuarioId = _usuarioId;

    if (usuarioId == null) {
      throw ApiException(
        'Usuário não identificado.',
      );
    }

    final uri = Uri.parse(
      '$baseUrl/listar_mensagens.php'
      '?solicitacao_id=$solicitacaoId'
      '&usuario_id=$usuarioId',
    );

    final response = await http
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
          },
        )
        .timeout(
          const Duration(seconds: 5),
        );

    final dados =
        await _decodificarResposta(
      response,
    );

    final lista =
        dados['mensagens'];

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

  Future<Map<String, dynamic>> enviarMensagem({
    required int solicitacaoId,
    required String mensagem,
  }) async {
    final usuarioId = _usuarioId;

    if (usuarioId == null) {
      throw ApiException(
        'Usuário não identificado.',
      );
    }

    final response = await http
        .post(
          Uri.parse(
            '$baseUrl/enviar_mensagem.php',
          ),
          headers: {
            'Content-Type':
                'application/json',
            'Accept':
                'application/json',
          },
          body: jsonEncode({
            'solicitacao_id':
                solicitacaoId,
            'remetente_id':
                usuarioId,
            'mensagem':
                mensagem.trim(),
          }),
        )
        .timeout(
          const Duration(seconds: 10),
        );

    return _decodificarResposta(
      response,
    );
  }

  // ============================================================
  // EXCLUIR CONTA
  // ============================================================

  /// Exclui a conta de quem está logado (pede a senha por segurança).
  /// Ao voltar com sucesso, a sessão local também é encerrada.
  Future<void> excluirConta({required String senha}) async {
    final usuarioId = _usuarioId;

    if (usuarioId == null) {
      throw ApiException('Usuário não identificado.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/excluir_conta.php'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'usuario_id': usuarioId,
            'senha': senha,
          }),
        )
        .timeout(const Duration(seconds: 15));

    // Sem o await, um erro do servidor (senha incorreta, por exemplo)
    // não chegaria aqui e a sessão era encerrada como se tivesse dado
    // certo, mesmo com a conta intacta no banco.
    final dados = await _decodificarResposta(response);

    if (dados['sucesso'] != true) {
      throw ApiException(
        (dados['mensagem'] ?? 'Não foi possível excluir a conta.')
            .toString(),
      );
    }

    logout();
  }

  // ============================================================
  // AVALIAR ATENDIMENTO
  // ============================================================

  Future<void> avaliarSolicitacao({
    required int solicitacaoId,
    required int nota,
    String comentario = '',
  }) async {
    final usuarioId = _usuarioId;

    if (usuarioId == null) {
      throw ApiException('Usuário não identificado.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/avaliar_solicitacao.php'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'solicitacao_id': solicitacaoId,
            'usuario_id': usuarioId,
            'nota': nota,
            'comentario': comentario.trim(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    await _decodificarResposta(response);
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
  // EDITAR VEÍCULO
  // ============================================================

  Future<Map<String, dynamic>> editarVeiculo({
    required int veiculoId,
    required String tipo,
    required String marca,
    required String modelo,
    required int ano,
    required String placa,
    required String cor,
  }) async {
    final id = _usuarioId;

    if (id == null) {
      throw ApiException(
        'Usuário não identificado. Faça login novamente.',
      );
    }

    if (_tipoUsuario != 'cliente') {
      throw ApiException(
        'Somente clientes podem editar veículos.',
      );
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/editar_veiculo.php'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'usuario_id': id,
            'veiculo_id': veiculoId,
            'tipo': tipo,
            'marca': marca,
            'modelo': modelo,
            'ano': ano,
            'placa': placa,
            'cor': cor,
          }),
        )
        .timeout(
          const Duration(seconds: 10),
        );

    return _decodificarResposta(response);
  }

  // ============================================================
  // DEFINIR VEÍCULO PADRÃO
  // ============================================================

  Future<Map<String, dynamic>> definirVeiculoPadrao(
    int veiculoId,
  ) async {
    final id = _usuarioId;

    if (id == null) {
      throw ApiException(
        'Usuário não identificado. Faça login novamente.',
      );
    }

    if (_tipoUsuario != 'cliente') {
      throw ApiException(
        'Somente clientes podem definir veículo padrão.',
      );
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/definir_veiculo_padrao.php'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'usuario_id': id,
            'veiculo_id': veiculoId,
          }),
        )
        .timeout(
          const Duration(seconds: 10),
        );

    return _decodificarResposta(response);
  }

  // ============================================================
  // HISTÓRICO DO CLIENTE
  // ============================================================

  Future<List<Map<String, dynamic>>> listarHistorico() async {
    final id = _usuarioId;

    if (id == null) {
      throw ApiException(
        'Usuário não identificado. Faça login novamente.',
      );
    }

    if (_tipoUsuario != 'cliente') {
      throw ApiException(
        'Somente clientes possuem histórico de resgates.',
      );
    }

    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/listar_historico.php?cliente_id=$id',
          ),
          headers: const {
            'Accept': 'application/json',
          },
        )
        .timeout(
          const Duration(seconds: 10),
        );

    final dados = await _decodificarResposta(response);
    final lista = dados['historico'];

    if (lista is! List) {
      return [];
    }

    return lista
        .map(
          (item) => Map<String, dynamic>.from(
            item as Map,
          ),
        )
        .toList();
  }

  // ============================================================
// EXCLUIR VEÍCULO
// ============================================================

Future<Map<String, dynamic>> excluirVeiculo(
  int veiculoId,
) async {
  final id = _usuarioId;

  if (id == null) {
    throw ApiException(
      'Usuário não identificado. Faça login novamente.',
    );
  }

  if (_tipoUsuario != 'cliente') {
    throw ApiException(
      'Somente clientes podem excluir veículos.',
    );
  }

  final response = await http
      .post(
        Uri.parse(
          '$baseUrl/excluir_veiculo.php',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'usuario_id': id,
          'veiculo_id': veiculoId,
        }),
      )
      .timeout(
        const Duration(seconds: 10),
      );

  return _decodificarResposta(response);
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