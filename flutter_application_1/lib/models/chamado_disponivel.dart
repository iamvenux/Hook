/// Chamado (solicitação de resgate) disponível para o socorrista aceitar.
class ChamadoDisponivel {
  final int id;

  final String nomeUsuario;
  final String? telefoneUsuario;

  final String servico;

  final double distanciaKm;

  final String endereco;

  final double latitude;
  final double longitude;

  final double valorEstimado;

  final String formaPagamento;

  final String veiculo;
  final String? placaVeiculo;

  final DateTime criadoEm;

  const ChamadoDisponivel({
    required this.id,
    required this.nomeUsuario,
    this.telefoneUsuario,
    required this.servico,
    required this.distanciaKm,
    required this.endereco,
    required this.latitude,
    required this.longitude,
    required this.valorEstimado,
    required this.formaPagamento,
    required this.veiculo,
    this.placaVeiculo,
    required this.criadoEm,
  });

  /// Monta o chamado a partir de um item retornado por
  /// `buscar_solicitacoes.php`.
  ///
  /// A distância não vem da API: é calculada por quem chama, a partir da
  /// posição atual do socorrista.
  factory ChamadoDisponivel.fromMap(
    Map<String, dynamic> item, {
    double distanciaKm = 0,
  }) {
    final clienteRaw = item['cliente'];
    final veiculoRaw = item['veiculo'];

    final cliente = clienteRaw is Map
        ? Map<String, dynamic>.from(clienteRaw)
        : <String, dynamic>{};

    final veiculo = veiculoRaw is Map
        ? Map<String, dynamic>.from(veiculoRaw)
        : <String, dynamic>{};

    final marca = veiculo['marca']?.toString() ?? '';
    final modelo = veiculo['modelo']?.toString() ?? '';

    final veiculoTexto = [marca, modelo]
        .where((valor) => valor.trim().isNotEmpty)
        .join(' ');

    DateTime criadoEm = DateTime.now();

    final dataRaw = item['created_at']?.toString();

    if (dataRaw != null) {
      try {
        criadoEm = DateTime.parse(
          dataRaw.replaceFirst(' ', 'T'),
        );
      } catch (_) {}
    }

    return ChamadoDisponivel(
      id: _paraInt(item['id']),
      nomeUsuario: cliente['nome']?.toString() ?? 'Cliente',
      telefoneUsuario: cliente['telefone']?.toString(),
      servico: item['tipo_reboque']?.toString() ?? 'Guincho',
      distanciaKm: distanciaKm,
      endereco: item['endereco']?.toString() ?? '',
      latitude: paraDouble(item['latitude']),
      longitude: paraDouble(item['longitude']),
      valorEstimado: paraDouble(item['valor_estimado']),
      formaPagamento: item['forma_pagamento']?.toString() ?? '',
      veiculo: veiculoTexto.isEmpty ? 'Veículo' : veiculoTexto,
      placaVeiculo: veiculo['placa']?.toString(),
      criadoEm: criadoEm,
    );
  }

  /// Converte um valor vindo do JSON (número ou texto) em double.
  static double paraDouble(dynamic valor) {
    if (valor is double) {
      return valor;
    }

    if (valor is int) {
      return valor.toDouble();
    }

    return double.tryParse(valor?.toString() ?? '') ?? 0;
  }

  static int _paraInt(dynamic valor) {
    if (valor is int) {
      return valor;
    }

    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }
}
