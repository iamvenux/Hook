import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_application_1/models/rota_calculada.dart';

/// Cálculo de rota de carro entre dois pontos, usando o OSRM público.
class RotaService {
  RotaService._();

  static final RotaService instance = RotaService._();

  /// Busca a rota entre [origem] e [destino].
  ///
  /// Devolve `null` se o OSRM falhar ou não encontrar rota — quem chama
  /// segue funcionando sem o traçado no mapa.
  Future<RotaCalculada?> buscarRota(
    LatLng origem,
    LatLng destino,
  ) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origem.longitude},${origem.latitude};'
      '${destino.longitude},${destino.latitude}'
      '?overview=full&geometries=polyline',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data['code'] != 'Ok') {
        return null;
      }

      final routes = data['routes'] as List;

      if (routes.isEmpty) {
        return null;
      }

      final rota = routes[0] as Map;

      return RotaCalculada(
        pontos: _decodificarPolyline(rota['geometry'] as String),
        duracaoSegundos: (rota['duration'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Decodifica o formato "encoded polyline" em uma lista de coordenadas.
  List<LatLng> _decodificarPolyline(String encoded) {
    final pontos = <LatLng>[];

    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int valor = 0;
      int b;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        valor |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      lat += (valor & 1) != 0 ? ~(valor >> 1) : (valor >> 1);

      shift = 0;
      valor = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        valor |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      lng += (valor & 1) != 0 ? ~(valor >> 1) : (valor >> 1);

      pontos.add(
        LatLng(lat / 1e5, lng / 1e5),
      );
    }

    return pontos;
  }
}
