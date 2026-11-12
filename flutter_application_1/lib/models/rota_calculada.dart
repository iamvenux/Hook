import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Rota entre dois pontos, devolvida pelo serviço de rotas.
class RotaCalculada {
  /// Pontos que formam o traçado da rota no mapa.
  final List<LatLng> pontos;

  /// Duração estimada do trajeto, em segundos.
  final int duracaoSegundos;

  const RotaCalculada({
    required this.pontos,
    required this.duracaoSegundos,
  });

  /// Duração estimada arredondada para cima, em minutos.
  int get minutos => (duracaoSegundos / 60).ceil();
}
