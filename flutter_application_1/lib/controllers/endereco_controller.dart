import 'package:flutter_application_1/models/endereco_salvo.dart';
import 'package:flutter_application_1/services/api_service.dart';

/// Endereços salvos do cliente (Casa, Trabalho...).
class EnderecoController {
  EnderecoController._();

  static final EnderecoController instance = EnderecoController._();

  final ApiService _api = ApiService.instance;

  Future<List<EnderecoSalvo>> listar() async {
    final lista = await _api.listarEnderecos();

    return lista.map(EnderecoSalvo.fromMap).toList();
  }

  /// Salva e devolve o endereço criado (com o id do servidor).
  Future<EnderecoSalvo> adicionar({
    required String apelido,
    required String endereco,
    required double latitude,
    required double longitude,
  }) async {
    final dados = await _api.adicionarEndereco(
      apelido: apelido,
      endereco: endereco,
      latitude: latitude,
      longitude: longitude,
    );

    final criadoRaw = dados['endereco'];

    if (criadoRaw is Map) {
      return EnderecoSalvo.fromMap(Map<String, dynamic>.from(criadoRaw));
    }

    return EnderecoSalvo(
      id: 0,
      apelido: apelido,
      endereco: endereco,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> excluir(int enderecoId) async {
    await _api.excluirEndereco(enderecoId);
  }
}
