import 'package:geolocator/geolocator.dart';

import 'package:flutter_application_1/models/chamado_disponivel.dart';
import 'package:flutter_application_1/models/resumo_ganhos.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/localizacao_service.dart';

/// Regras do lado do socorrista: disponibilidade, envio de localização,
/// busca de chamados e aceite.
class SocorristaController {
  SocorristaController._();

  static final SocorristaController instance = SocorristaController._();

  final ApiService _api = ApiService.instance;

  final LocalizacaoService _localizacao = LocalizacaoService.instance;

  /// Nome do socorrista logado.
  String get nomeSocorrista => _api.nomeUsuario ?? 'Motorista';

  /// Texto curto do tipo de atuação, ex.: `Guincho Leve`.
  String get tipoAtuacao {
    final tipo = _api.tipoGuincho;

    if (tipo == null || tipo.isEmpty) {
      return 'Motorista';
    }

    return 'Guincho $tipo';
  }

  // ============================================================
  // DISPONIBILIDADE
  // ============================================================

  /// Salva a posição inicial e marca o socorrista como disponível.
  Future<void> ficarOnline(Position posicao) async {
    await enviarLocalizacao(posicao);

    await _api.atualizarDisponibilidade(
      disponivel: true,
    );
  }

  Future<void> ficarOffline() async {
    await _api.atualizarDisponibilidade(
      disponivel: false,
    );
  }

  /// Envia a posição atual do socorrista para o servidor.
  Future<void> enviarLocalizacao(Position posicao) async {
    await _api.atualizarLocalizacao(
      latitude: posicao.latitude,
      longitude: posicao.longitude,
    );
  }

  // ============================================================
  // CHAMADOS
  // ============================================================

  /// Solicitações abertas, do jeito que a API devolve.
  Future<List<Map<String, dynamic>>> buscarSolicitacoes() {
    return _api.buscarSolicitacoes();
  }

  /// Converte as solicitações em chamados, calculando a distância até
  /// [posicaoAtual], e ordena dos mais próximos para os mais distantes.
  List<ChamadoDisponivel> montarChamados(
    List<Map<String, dynamic>> solicitacoes, {
    Position? posicaoAtual,
  }) {
    final lista = <ChamadoDisponivel>[];

    for (final item in solicitacoes) {
      double distanciaKm = 0;

      if (posicaoAtual != null) {
        distanciaKm = _localizacao.distanciaEmKm(
          posicaoAtual.latitude,
          posicaoAtual.longitude,
          ChamadoDisponivel.paraDouble(item['latitude']),
          ChamadoDisponivel.paraDouble(item['longitude']),
        );
      }

      lista.add(
        ChamadoDisponivel.fromMap(
          item,
          distanciaKm: distanciaKm,
        ),
      );
    }

    lista.sort(
      (a, b) => a.distanciaKm.compareTo(b.distanciaKm),
    );

    return lista;
  }

  // ============================================================
  // GANHOS
  // ============================================================

  /// Totais e lista de atendimentos concluídos do socorrista logado.
  Future<ResumoGanhos> listarGanhos() async {
    final dados = await _api.listarGanhos();

    return ResumoGanhos.fromMap(dados);
  }

  /// Aceita o chamado e já muda o status para "a caminho".
  Future<void> aceitarChamado(int solicitacaoId) async {
    await _api.aceitarSolicitacao(
      solicitacaoId: solicitacaoId,
    );

    await _api.atualizarStatus(
      solicitacaoId: solicitacaoId,
      status: 'a_caminho',
    );
  }

  /// Avança o status do atendimento no servidor
  /// (`no_local`, `em_atendimento`, `concluido`).
  /// O backend recusa voltar para um status anterior.
  Future<void> atualizarStatus({
    required int solicitacaoId,
    required String status,
  }) async {
    await _api.atualizarStatus(
      solicitacaoId: solicitacaoId,
      status: status,
    );
  }
}
