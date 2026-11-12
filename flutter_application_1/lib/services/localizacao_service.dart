import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Resultado da verificação de GPS + permissão de localização.
enum StatusLocalizacao {
  permitido,
  servicoDesativado,
  permissaoNegada,
}

/// Acesso ao GPS do aparelho e conversão de coordenada em endereço.
class LocalizacaoService {
  LocalizacaoService._();

  static final LocalizacaoService instance = LocalizacaoService._();

  /// Confere se o GPS está ligado e pede a permissão se ainda não foi dada.
  Future<StatusLocalizacao> verificarPermissao() async {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();

    if (!servicoAtivo) {
      return StatusLocalizacao.servicoDesativado;
    }

    var permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      return StatusLocalizacao.permissaoNegada;
    }

    return StatusLocalizacao.permitido;
  }

  /// Posição atual do aparelho.
  ///
  /// Com [paraNavegacao] usa a maior precisão disponível.
  Future<Position> obterPosicaoAtual({
    bool paraNavegacao = false,
  }) {
    return Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: paraNavegacao
            ? LocationAccuracy.bestForNavigation
            : LocationAccuracy.high,
      ),
    );
  }

  /// Endereço formatado da coordenada, ou `null` se não der para converter.
  Future<String?> enderecoPorCoordenada(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return null;
      }

      final p = placemarks.first;

      final rua = p.thoroughfare?.trim() ?? '';
      final numero = p.subThoroughfare?.trim() ?? '';
      final bairro = p.subLocality?.trim() ?? '';
      final cidade = p.locality?.trim() ?? '';
      final estado = p.administrativeArea?.trim() ?? '';
      final cep = p.postalCode?.trim() ?? '';

      final partes = <String>[];

      if (rua.isNotEmpty) {
        partes.add(numero.isNotEmpty ? '$rua, $numero' : rua);
      }

      if (bairro.isNotEmpty) {
        partes.add(bairro);
      }

      if (cidade.isNotEmpty) {
        partes.add(estado.isNotEmpty ? '$cidade - $estado' : cidade);
      }

      if (cep.isNotEmpty) {
        partes.add('CEP $cep');
      }

      return partes.isEmpty ? null : partes.join(', ');
    } catch (_) {
      return null;
    }
  }

  /// Distância em linha reta entre dois pontos, em quilômetros.
  double distanciaEmKm(
    double latitudeOrigem,
    double longitudeOrigem,
    double latitudeDestino,
    double longitudeDestino,
  ) {
    final metros = Geolocator.distanceBetween(
      latitudeOrigem,
      longitudeOrigem,
      latitudeDestino,
      longitudeDestino,
    );

    return metros / 1000;
  }
}
