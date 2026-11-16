import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Carrinho do motorista no mapa (círculo azul com um carro branco).
/// Usado na tela do motorista e na do cliente, para os dois verem
/// o mesmo símbolo.
Future<BitmapDescriptor> criarIconeCarro() async {
  const size = 132.0;
  const azul = Color(0xFF1A7EF5);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final branco = Paint()..color = Colors.white;
  final centro = const Offset(size / 2, size / 2);

  // sombra leve
  canvas.drawCircle(
    centro.translate(0, 3),
    size / 2 - 3,
    Paint()..color = Colors.black26,
  );

  canvas.drawCircle(centro, size / 2 - 4, Paint()..color = azul);
  canvas.drawCircle(
    centro,
    size / 2 - 7,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5,
  );

  // carroceria
  canvas.drawRRect(
    RRect.fromRectAndCorners(
      const Rect.fromLTWH(24, 58, 84, 30),
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
      bottomLeft: const Radius.circular(6),
      bottomRight: const Radius.circular(6),
    ),
    branco,
  );

  // cabine
  canvas.drawRRect(
    RRect.fromRectAndCorners(
      const Rect.fromLTWH(37, 42, 58, 22),
      topLeft: const Radius.circular(11),
      topRight: const Radius.circular(11),
    ),
    branco,
  );

  // janelas
  final janela = Paint()..color = azul;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(43, 48, 20, 12),
      const Radius.circular(3),
    ),
    janela,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(69, 48, 20, 12),
      const Radius.circular(3),
    ),
    janela,
  );

  // rodas
  for (final x in [42.0, 90.0]) {
    canvas.drawCircle(Offset(x, 90), 11, branco);
    canvas.drawCircle(Offset(x, 90), 11, Paint()
      ..color = azul
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    canvas.drawCircle(Offset(x, 90), 5, Paint()..color = azul);
  }

  final img = await recorder.endRecording().toImage(
        size.toInt(),
        size.toInt(),
      );
  final dados = await img.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.bytes(
    dados!.buffer.asUint8List(),
    width: 46,
    height: 46,
  );
}
