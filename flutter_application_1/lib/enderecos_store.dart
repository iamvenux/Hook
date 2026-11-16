import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

/// Endereço que o usuário salvou com um apelido (Casa, Trabalho...).
class EnderecoSalvo {
  final String id;
  final String apelido;

  /// 'casa', 'trabalho' ou 'outro'
  final String tipo;
  final String endereco;
  final double lat;
  final double lng;

  const EnderecoSalvo({
    required this.id,
    required this.apelido,
    required this.tipo,
    required this.endereco,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'apelido': apelido,
        'tipo': tipo,
        'endereco': endereco,
        'lat': lat,
        'lng': lng,
      };

  factory EnderecoSalvo.fromJson(Map<String, dynamic> json) {
    return EnderecoSalvo(
      id: json['id'].toString(),
      apelido: (json['apelido'] ?? '').toString(),
      tipo: (json['tipo'] ?? 'outro').toString(),
      endereco: (json['endereco'] ?? '').toString(),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

/// Endereço usado recentemente como ponto de encontro.
class EnderecoRecente {
  final String endereco;
  final double lat;
  final double lng;

  const EnderecoRecente({
    required this.endereco,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() => {
        'endereco': endereco,
        'lat': lat,
        'lng': lng,
      };

  factory EnderecoRecente.fromJson(Map<String, dynamic> json) {
    return EnderecoRecente(
      endereco: (json['endereco'] ?? '').toString(),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

/// Guarda endereços salvos e recentes no aparelho (shared_preferences),
/// separados por usuário logado.
class EnderecosStore {
  EnderecosStore._();

  static const int _maxRecentes = 8;

  static String get _usuario =>
      (ApiService.instance.usuarioId ?? 0).toString();

  static String get _chaveSalvos => 'enderecos_salvos_$_usuario';
  static String get _chaveRecentes => 'enderecos_recentes_$_usuario';

  // ------------------------------------------------------------
  // SALVOS
  // ------------------------------------------------------------

  static Future<List<EnderecoSalvo>> listarSalvos() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(_chaveSalvos);

    if (bruto == null || bruto.isEmpty) return [];

    try {
      final lista = jsonDecode(bruto) as List;

      return lista
          .map((e) => EnderecoSalvo.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _gravarSalvos(List<EnderecoSalvo> lista) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _chaveSalvos,
      jsonEncode(lista.map((e) => e.toJson()).toList()),
    );
  }

  /// Adiciona ou atualiza (pelo id). "Casa" e "Trabalho" são únicos:
  /// salvar um novo substitui o anterior do mesmo tipo.
  static Future<void> salvar(EnderecoSalvo novo) async {
    final lista = await listarSalvos();

    lista.removeWhere((e) =>
        e.id == novo.id ||
        (novo.tipo != 'outro' && e.tipo == novo.tipo));

    lista.add(novo);

    await _gravarSalvos(lista);
  }

  static Future<void> remover(String id) async {
    final lista = await listarSalvos();

    lista.removeWhere((e) => e.id == id);

    await _gravarSalvos(lista);
  }

  // ------------------------------------------------------------
  // RECENTES
  // ------------------------------------------------------------

  static Future<List<EnderecoRecente>> listarRecentes() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(_chaveRecentes);

    if (bruto == null || bruto.isEmpty) return [];

    try {
      final lista = jsonDecode(bruto) as List;

      return lista
          .map((e) => EnderecoRecente.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> registrarRecente(
    String endereco,
    double lat,
    double lng,
  ) async {
    final texto = endereco.trim();

    if (texto.isEmpty ||
        texto == 'Buscando endereço...' ||
        texto == 'Endereço não encontrado') {
      return;
    }

    final lista = await listarRecentes();

    lista.removeWhere((e) => e.endereco == texto);

    lista.insert(
      0,
      EnderecoRecente(endereco: texto, lat: lat, lng: lng),
    );

    if (lista.length > _maxRecentes) {
      lista.removeRange(_maxRecentes, lista.length);
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _chaveRecentes,
      jsonEncode(lista.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> limparRecentes() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_chaveRecentes);
  }
}
