import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Um endereço encontrado pela busca.
class ResultadoEndereco {
  final String titulo;
  final String subtitulo;
  final String endereco;
  final double lat;
  final double lng;

  const ResultadoEndereco({
    required this.titulo,
    required this.subtitulo,
    required this.endereco,
    required this.lat,
    required this.lng,
  });
}

/// Falha de rede/servidor na busca (diferente de "não achou nada").
class BuscaEnderecoException implements Exception {
  final String mensagem;

  const BuscaEnderecoException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Busca de endereços pelo Nominatim (OpenStreetMap): gratuito, sem chave.
///
/// Regras de uso do serviço respeitadas aqui:
///  - identificação do app no User-Agent;
///  - no máximo ~1 consulta por segundo (controle em [_esperarVez]);
///  - resultados restritos ao Brasil.
///
/// O mapa e a conversão de ponto -> endereço continuam no `geocoding`.
class BuscaEndereco {
  BuscaEndereco._();

  static const String _host = 'nominatim.openstreetmap.org';
  static const String _userAgent =
      'HookApp/1.0 (projeto TCC FATEC Sao Roque)';

  static DateTime _ultimaConsulta =
      DateTime.fromMillisecondsSinceEpoch(0);

  static Future<void> _esperarVez() async {
    const intervalo = Duration(milliseconds: 1100);

    final passou = DateTime.now().difference(_ultimaConsulta);

    if (passou < intervalo) {
      await Future.delayed(intervalo - passou);
    }

    _ultimaConsulta = DateTime.now();
  }

  /// "r. antonio rocha 120" -> "Rua antonio rocha 120" (abreviações comuns).
  static String _normalizar(String consulta) {
    var texto = consulta.trim().replaceAll(RegExp(r'\s+'), ' ');

    const abreviacoes = {
      'r': 'Rua',
      'av': 'Avenida',
      'avd': 'Avenida',
      'rod': 'Rodovia',
      'tv': 'Travessa',
      'trav': 'Travessa',
      'al': 'Alameda',
      'estr': 'Estrada',
      'pc': 'Praça',
      'pça': 'Praça',
    };

    final m = RegExp(r'^([A-Za-zçÇãÃ]{1,5})\.?\s+(.*)$').firstMatch(texto);

    if (m != null) {
      final chave = m.group(1)!.toLowerCase();

      if (abreviacoes.containsKey(chave)) {
        texto = '${abreviacoes[chave]} ${m.group(2)}';
      }
    }

    return texto;
  }

  static String _sem(String t) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';

    var r = t.toLowerCase();

    for (var i = 0; i < de.length; i++) {
      r = r.replaceAll(de[i], para[i]);
    }

    return r;
  }

  /// Procura endereços. [perto] e [cidade] mantêm a busca na região de
  /// quem está procurando (evita cair em bairro de outra cidade).
  ///
  /// Estratégia (para no primeiro passo que achar algo):
  ///  1. texto completo + cidade, só na região;
  ///  2. só a rua (+ cidade), na região, recolocando o número digitado;
  ///  3. texto completo + cidade, sem limite de região.
  static Future<List<ResultadoEndereco>> buscar(
    String consulta, {
    ({double lat, double lng})? perto,
    String? cidade,
  }) async {
    final base = _normalizar(consulta);

    final partes = base
        .split(RegExp(r'\s*(?:,|;|\s-\s)\s*'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    final rua = partes.isEmpty ? base : partes.first;

    // "Rua X, 259, Vila Y" ou "Rua X 259, Vila Y": acha o número e o bairro
    // em qualquer posição.
    String? numero;
    var bairro = '';

    final mNumRua =
        RegExp(r'(?<![\w])(\d{1,5})(?![\w])').firstMatch(rua);

    if (mNumRua != null) numero = mNumRua.group(1);

    for (final p in partes.skip(1)) {
      final soNumero = RegExp(r'^\d{1,5}$').hasMatch(p.trim());

      if (soNumero) {
        numero ??= p.trim();
      } else if (bairro.isEmpty) {
        bairro = p.trim();
      }
    }

    final ruaSemNumero = rua
        .replaceAll(RegExp(r'(?<![\w])\d{1,5}(?![\w])'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final cid = (cidade ?? '').trim();

    String comCidade(String t) {
      if (cid.isEmpty || _sem(t).contains(_sem(cid))) return t;

      return '$t, $cid';
    }

    final temRegiao = perto != null;

    // 1) completo, só na região
    var resultados = await _consultar(
      comCidade(base),
      perto,
      local: temRegiao,
    );

    // 2) só a rua, na região (o número digitado volta no título)
    if (resultados.isEmpty &&
        ruaSemNumero.length >= 3 &&
        (numero != null || bairro.isNotEmpty)) {
      resultados = await _consultar(
        comCidade(ruaSemNumero),
        perto,
        local: temRegiao,
      );

    }

    // 3) completo, sem restringir à região
    if (resultados.isEmpty && temRegiao) {
      resultados = await _consultar(comCidade(base), perto, local: false);
    }

    // O que a pessoa digitou (número e bairro) vale mais do que o cadastro
    // do mapa, que quase nunca tem cada casa.
    resultados = resultados
        .map((r) => _aplicarDigitado(r, ruaSemNumero, numero, bairro))
        .toList();

    // Se digitou o bairro, o que combina com ele aparece primeiro.
    if (bairro.isNotEmpty && resultados.length > 1) {
      final alvo = _sem(bairro);

      final bate = <ResultadoEndereco>[];
      final resto = <ResultadoEndereco>[];

      for (final r in resultados) {
        (_sem(r.subtitulo).contains(alvo) ? bate : resto).add(r);
      }

      resultados = [...bate, ...resto];
    }

    return resultados;
  }

  static const _prefixos = {
    'rua', 'r', 'avenida', 'av', 'avd', 'rodovia', 'rod', 'travessa',
    'tv', 'trav', 'alameda', 'al', 'estrada', 'estr', 'praca', 'pc',
    'da', 'de', 'do', 'das', 'dos',
  };

  static Set<String> _palavras(String t) => _sem(t)
      .split(RegExp(r'[^a-z0-9]+'))
      .where((p) => p.isNotEmpty && !_prefixos.contains(p))
      .toSet();

  /// Se o resultado é a mesma rua que a pessoa digitou, usa o número e o
  /// bairro digitados no lugar dos do mapa.
  static ResultadoEndereco _aplicarDigitado(
    ResultadoEndereco r,
    String ruaDigitada,
    String? numero,
    String bairro,
  ) {
    if (numero == null && bairro.isEmpty) return r;

    final nomeResultado = r.titulo.split(',').first.trim();
    final alvo = _palavras(ruaDigitada);

    if (alvo.isEmpty || !_palavras(nomeResultado).containsAll(alvo)) {
      return r;
    }

    // "São Roque - SP" (cidade e UF que o mapa devolveu)
    final partesSub = r.subtitulo.split(',').map((e) => e.trim()).toList();
    final cidadeUf = partesSub.isEmpty ? '' : partesSub.last;

    final titulo = numero != null ? '$nomeResultado, $numero' : nomeResultado;

    final sub = bairro.isNotEmpty
        ? [bairro, cidadeUf].where((e) => e.isNotEmpty).join(', ')
        : r.subtitulo;

    final cidadeSo = cidadeUf.split(' - ').first.trim();

    final endereco = [
      titulo,
      bairro.isNotEmpty
          ? bairro
          : (partesSub.length > 1 ? partesSub.first : ''),
      cidadeSo,
    ].where((e) => e.isNotEmpty).join(', ');

    return ResultadoEndereco(
      titulo: titulo,
      subtitulo: sub,
      endereco: endereco,
      lat: r.lat,
      lng: r.lng,
    );
  }

  static Future<List<ResultadoEndereco>> _consultar(
    String texto,
    ({double lat, double lng})? perto, {
    bool local = false,
  }) async {
    await _esperarVez();

    final params = <String, String>{
      'q': texto,
      'format': 'jsonv2',
      'addressdetails': '1',
      'countrycodes': 'br',
      'limit': '8',
      'accept-language': 'pt-BR',
    };

    if (perto != null) {
      final folga = local ? 0.25 : 0.6; // ~28 km ou ~65 km em volta
      params['viewbox'] = [
        perto.lng - folga,
        perto.lat + folga,
        perto.lng + folga,
        perto.lat - folga,
      ].map((v) => v.toStringAsFixed(5)).join(',');
      params['bounded'] = local ? '1' : '0';
    }

    final http.Response resposta;

    try {
      resposta = await http
          .get(
            Uri.https(_host, '/search', params),
            headers: {
              'User-Agent': _userAgent,
              'Accept': 'application/json',
              'Accept-Language': 'pt-BR',
            },
          )
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const BuscaEnderecoException('A busca demorou demais.');
    } catch (_) {
      throw const BuscaEnderecoException('Sem conexão com a busca.');
    }

    if (resposta.statusCode != 200) {
      throw BuscaEnderecoException(
        'Busca indisponível (${resposta.statusCode}).',
      );
    }

    final dynamic corpo;

    try {
      corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
    } catch (_) {
      throw const BuscaEnderecoException('Resposta inválida da busca.');
    }

    if (corpo is! List) return [];

    final lista = <ResultadoEndereco>[];

    for (final item in corpo) {
      if (item is! Map) continue;

      final r = _converter(item);

      if (r != null) lista.add(r);
    }

    return lista;
  }

  static String _txt(dynamic v) => (v ?? '').toString().trim();

  static String _primeiro(Map a, List<String> chaves) {
    for (final c in chaves) {
      final v = _txt(a[c]);

      if (v.isNotEmpty) return v;
    }

    return '';
  }

  static ResultadoEndereco? _converter(Map item) {
    final lat = double.tryParse(_txt(item['lat']));
    final lng = double.tryParse(_txt(item['lon']));

    if (lat == null || lng == null) return null;

    final a = item['address'] is Map ? item['address'] as Map : const {};

    final rua = _primeiro(
      a,
      ['road', 'pedestrian', 'footway', 'path', 'residential', 'highway'],
    );

    final numero = _txt(a['house_number']);

    final bairro = _primeiro(
      a,
      ['suburb', 'neighbourhood', 'quarter', 'city_district', 'borough'],
    );

    final cidade = _primeiro(
      a,
      ['city', 'town', 'village', 'municipality', 'county'],
    );

    final iso = _txt(a['ISO3166-2-lvl4']);
    final uf = iso.startsWith('BR-') ? iso.substring(3) : '';

    var titulo = '';

    if (rua.isNotEmpty) {
      titulo = numero.isNotEmpty ? '$rua, $numero' : rua;
    } else {
      // comércio, praça, ponto de referência...
      titulo = _txt(item['name']);

      if (titulo.isEmpty) {
        titulo = _txt(item['display_name']).split(',').first.trim();
      }
    }

    if (titulo.isEmpty) return null;

    final cidadeUf = cidade.isEmpty
        ? ''
        : (uf.isEmpty ? cidade : '$cidade - $uf');

    final subtitulo =
        [bairro, cidadeUf].where((e) => e.isNotEmpty).join(', ');

    final endereco = [titulo, bairro, cidade]
        .where((e) => e.isNotEmpty)
        .join(', ');

    return ResultadoEndereco(
      titulo: titulo,
      subtitulo: subtitulo,
      endereco: endereco,
      lat: lat,
      lng: lng,
    );
  }
}
