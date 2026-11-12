import 'package:flutter_application_1/models/api_exception.dart';
import 'package:flutter_application_1/services/api_service.dart';

/// Regras das solicitações de resgate do lado do cliente:
/// criar, acompanhar, cancelar e consultar o histórico.
class SolicitacaoController {
  SolicitacaoController._();

  static final SolicitacaoController instance = SolicitacaoController._();

  final ApiService _api = ApiService.instance;

  /// Converte um texto como `R$ 1.250,00` em número.
  /// Devolve `null` se o texto estiver vazio ou não for um valor válido.
  static double? parseValorMonetario(String valor) {
    var texto = valor.trim().replaceAll('R\$', '').replaceAll(' ', '');

    if (texto.isEmpty) {
      return null;
    }

    if (texto.contains(',')) {
      texto = texto.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(texto);
  }

  /// Cria a solicitação e devolve o ID gerado pelo servidor.
  Future<int> criarSolicitacao({
    required int veiculoId,
    required String tipoReboque,
    required String formaPagamento,
    required String endereco,
    required double latitude,
    required double longitude,
    bool precisaTroco = false,
    double? trocoPara,
  }) async {
    final solicitacao = await _api.criarSolicitacao(
      veiculoId: veiculoId,
      tipoReboque: tipoReboque,
      formaPagamento: formaPagamento,
      endereco: endereco,
      latitude: latitude,
      longitude: longitude,
      precisaTroco: precisaTroco,
      trocoPara: trocoPara,
    );

    final idRaw =
        solicitacao['id'] ?? (solicitacao['solicitacao'] as Map?)?['id'];

    final solicitacaoId =
        idRaw is int ? idRaw : int.tryParse(idRaw.toString());

    if (solicitacaoId == null) {
      throw ApiException(
        'O servidor não retornou o ID da solicitação.',
      );
    }

    return solicitacaoId;
  }

  /// Situação atual da solicitação (status, mensagem e motorista).
  Future<Map<String, dynamic>> consultarSolicitacao(
    int solicitacaoId,
  ) {
    return _api.consultarSolicitacao(solicitacaoId);
  }

  Future<Map<String, dynamic>> cancelarSolicitacao(
    int solicitacaoId,
  ) {
    return _api.cancelarSolicitacao(solicitacaoId);
  }

  /// Resgates já solicitados pelo cliente logado.
  Future<List<Map<String, dynamic>>> listarHistorico() {
    return _api.listarHistorico();
  }
}
