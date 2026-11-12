import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Chamado que o socorrista já aceitou e está atendendo.
class ChamadoAceito {
  final int id;
  final String nomeUsuario;
  final String servico;
  final LatLng coordenadaUsuario;
  final String enderecoUsuario;
  final double distanciaKm;

  const ChamadoAceito({
    required this.id,
    required this.nomeUsuario,
    required this.servico,
    required this.coordenadaUsuario,
    required this.enderecoUsuario,
    required this.distanciaKm,
  });
}
