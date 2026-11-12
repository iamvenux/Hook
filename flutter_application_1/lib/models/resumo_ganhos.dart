/// Um atendimento concluído pelo socorrista, com o valor recebido.
class AtendimentoConcluido {
  final int id;
  final String servico;
  final String formaPagamento;
  final String endereco;
  final double valor;
  final String nomeCliente;
  final DateTime? concluidoEm;

  const AtendimentoConcluido({
    required this.id,
    required this.servico,
    required this.formaPagamento,
    required this.endereco,
    required this.valor,
    required this.nomeCliente,
    this.concluidoEm,
  });

  factory AtendimentoConcluido.fromMap(Map<String, dynamic> map) {
    final clienteRaw = map['cliente'];
    final cliente = clienteRaw is Map
        ? Map<String, dynamic>.from(clienteRaw)
        : <String, dynamic>{};

    DateTime? concluidoEm;
    final dataRaw = map['concluido_em']?.toString();

    if (dataRaw != null && dataRaw.isNotEmpty) {
      concluidoEm = DateTime.tryParse(dataRaw.replaceFirst(' ', 'T'));
    }

    return AtendimentoConcluido(
      id: _paraInt(map['id']),
      servico: map['tipo_reboque']?.toString() ?? 'Guincho',
      formaPagamento: map['forma_pagamento']?.toString() ?? '',
      endereco: map['endereco']?.toString() ?? '',
      valor: _paraDouble(map['valor']),
      nomeCliente: cliente['nome']?.toString() ?? 'Cliente',
      concluidoEm: concluidoEm,
    );
  }

  static int _paraInt(dynamic valor) {
    if (valor is int) return valor;
    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  static double _paraDouble(dynamic valor) {
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor?.toString() ?? '') ?? 0;
  }
}

/// Totais de ganhos do socorrista + lista de atendimentos concluídos,
/// como devolvido por `listar_ganhos.php`.
class ResumoGanhos {
  final double totalGeral;
  final double totalMes;
  final int quantidade;
  final List<AtendimentoConcluido> atendimentos;

  const ResumoGanhos({
    required this.totalGeral,
    required this.totalMes,
    required this.quantidade,
    required this.atendimentos,
  });

  factory ResumoGanhos.fromMap(Map<String, dynamic> map) {
    final resumoRaw = map['resumo'];
    final resumo = resumoRaw is Map
        ? Map<String, dynamic>.from(resumoRaw)
        : <String, dynamic>{};

    final listaRaw = map['atendimentos'];
    final atendimentos = listaRaw is List
        ? listaRaw
            .whereType<Map>()
            .map((item) => AtendimentoConcluido.fromMap(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
        : <AtendimentoConcluido>[];

    return ResumoGanhos(
      totalGeral: AtendimentoConcluido._paraDouble(resumo['total_geral']),
      totalMes: AtendimentoConcluido._paraDouble(resumo['total_mes']),
      quantidade: AtendimentoConcluido._paraInt(resumo['quantidade']),
      atendimentos: atendimentos,
    );
  }

  /// Valor médio por atendimento (0 quando não há nenhum).
  double get ticketMedio => quantidade == 0 ? 0 : totalGeral / quantidade;
}
