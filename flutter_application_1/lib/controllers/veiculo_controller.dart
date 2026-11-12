import 'package:flutter_application_1/services/api_service.dart';

/// Regras dos veículos do cliente: listar, cadastrar, editar,
/// excluir e definir o veículo padrão.
class VeiculoController {
  VeiculoController._();

  static final VeiculoController instance = VeiculoController._();

  final ApiService _api = ApiService.instance;

  Future<List<Map<String, dynamic>>> listarVeiculos() {
    return _api.listarVeiculos();
  }

  Future<Map<String, dynamic>> adicionarVeiculo({
    required String tipo,
    required String marca,
    required String modelo,
    required int ano,
    required String placa,
    required String cor,
  }) {
    return _api.adicionarVeiculo(
      tipo: tipo,
      marca: marca,
      modelo: modelo,
      ano: ano,
      placa: placa,
      cor: cor,
    );
  }

  Future<Map<String, dynamic>> editarVeiculo({
    required int veiculoId,
    required String tipo,
    required String marca,
    required String modelo,
    required int ano,
    required String placa,
    required String cor,
  }) {
    return _api.editarVeiculo(
      veiculoId: veiculoId,
      tipo: tipo,
      marca: marca,
      modelo: modelo,
      ano: ano,
      placa: placa,
      cor: cor,
    );
  }

  Future<Map<String, dynamic>> excluirVeiculo(
    int veiculoId,
  ) {
    return _api.excluirVeiculo(veiculoId);
  }

  Future<Map<String, dynamic>> definirVeiculoPadrao(
    int veiculoId,
  ) {
    return _api.definirVeiculoPadrao(veiculoId);
  }
}
