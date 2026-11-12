/// Endereço salvo pelo cliente (ex.: Casa, Trabalho).
class EnderecoSalvo {
  final int id;
  final String apelido;
  final String endereco;
  final double latitude;
  final double longitude;

  const EnderecoSalvo({
    required this.id,
    required this.apelido,
    required this.endereco,
    required this.latitude,
    required this.longitude,
  });

  factory EnderecoSalvo.fromMap(Map<String, dynamic> map) {
    return EnderecoSalvo(
      id: _paraInt(map['id']),
      apelido: map['apelido']?.toString() ?? '',
      endereco: map['endereco']?.toString() ?? '',
      latitude: _paraDouble(map['latitude']),
      longitude: _paraDouble(map['longitude']),
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
