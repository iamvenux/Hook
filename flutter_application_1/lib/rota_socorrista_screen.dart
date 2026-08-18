import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

// ─────────────────────────────────────────────
//  Tela de rota ativa do socorrista
// ─────────────────────────────────────────────
class RotaSocorristaScreen extends StatefulWidget {
  final ChamadoAceito chamado;

  /// Posição atual do socorrista (simula GPS)
  final LatLng coordenadaSocorrista;

  const RotaSocorristaScreen({
    super.key,
    required this.chamado,
    required this.coordenadaSocorrista,
  });

  @override
  State<RotaSocorristaScreen> createState() => _RotaSocorristaScreenState();
}

class _RotaSocorristaScreenState extends State<RotaSocorristaScreen> {
  // ── Cores (mesmo padrão da tela do usuário) ──
  static const Color azulPrincipal  = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto     = Color(0xFF9CB1C9);
  static const Color cardEscuro     = Color(0xFF1C2C3E);
  static const Color verdeStatus    = Color(0xFF22C55E);

  // ── Status do atendimento ─────────────────
  // 0 = a caminho | 1 = no local | 2 = em atendimento | 3 = concluído
  int _statusIndex = 0;

  final List<_StatusInfo> _statusList = const [
    _StatusInfo('A caminho',        Icons.directions_car_rounded,   Color(0xFF1A7EF5)),
    _StatusInfo('No local',         Icons.location_on_rounded,      Color(0xFFF59E0B)),
    _StatusInfo('Em atendimento',   Icons.build_rounded,            Color(0xFF8B5CF6)),
    _StatusInfo('Concluído',        Icons.check_circle_rounded,     Color(0xFF22C55E)),
  ];

  // ── Mapa ──────────────────────────────────
  GoogleMapController?  _mapController;
  Set<Marker>           _markers   = {};
  Set<Polyline>         _polylines = {};

  // ── Painel ────────────────────────────────
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  static const double _painelInicial = 0.38;
  static const double _painelExpandido = 0.72;

  // ── Rota ──────────────────────────────────
  String _tempoEstimado = '--';
  bool   _rotaCarregada = false;

  @override
  void initState() {
    super.initState();
    _configurarMarkers();
    _buscarRota();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ─── Markers ──────────────────────────────
  Future<void> _configurarMarkers() async {
    final iconeUsuario   = await _criarIconePin(Colors.red);
    final iconeSocorrista = await _criarIconeCarro();

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('usuario'),
          position: widget.chamado.coordenadaUsuario,
          icon: iconeUsuario,
          infoWindow: InfoWindow(
            title: widget.chamado.nomeUsuario,
            snippet: widget.chamado.enderecoUsuario,
          ),
        ),
        Marker(
          markerId: const MarkerId('socorrista'),
          position: widget.coordenadaSocorrista,
          icon: iconeSocorrista,
          infoWindow: const InfoWindow(title: 'Você'),
        ),
      };
    });
  }

  // ─── Ícone pin vermelho (usuário) ─────────
  Future<BitmapDescriptor> _criarIconePin(Color cor) async {
    const size = 80.0;
    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);
    final paint    = Paint()..color = cor;

    // Círculo
    canvas.drawCircle(const Offset(size / 2, size / 2 - 10), 22, paint);
    // Ponta
    final path = Path()
      ..moveTo(size / 2 - 10, size / 2 + 10)
      ..lineTo(size / 2 + 10, size / 2 + 10)
      ..lineTo(size / 2, size / 2 + 30)
      ..close();
    canvas.drawPath(path, paint);
    // Branco interno
    canvas.drawCircle(
      const Offset(size / 2, size / 2 - 10), 12,
      Paint()..color = Colors.white,
    );

    final picture = recorder.endRecording();
    final img     = await picture.toImage(size.toInt(), (size * 0.9).toInt());
    final data    = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // ─── Ícone carro azul (socorrista) ────────
  Future<BitmapDescriptor> _criarIconeCarro() async {
    const size = 80.0;
    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);
    final branco   = Paint()..color = Colors.white;

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = azulPrincipal,
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(12, 34, 56, 22),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
        bottomLeft: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      ),
      branco,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(20, 24, 38, 14),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      ),
      branco,
    );
    canvas.drawCircle(const Offset(24, 57), 7, branco);
    canvas.drawCircle(const Offset(24, 57), 4, Paint()..color = azulPrincipal);
    canvas.drawCircle(const Offset(56, 57), 7, branco);
    canvas.drawCircle(const Offset(56, 57), 4, Paint()..color = azulPrincipal);

    final picture = recorder.endRecording();
    final img     = await picture.toImage(size.toInt(), size.toInt());
    final data    = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // ─── Busca rota OSRM ──────────────────────
  Future<void> _buscarRota() async {
    final origem  = widget.coordenadaSocorrista;
    final destino = widget.chamado.coordenadaUsuario;

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origem.longitude},${origem.latitude};'
      '${destino.longitude},${destino.latitude}'
      '?overview=full&geometries=polyline',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return;
      final data   = json.decode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return;
      final routes = data['routes'] as List;
      if (routes.isEmpty) return;

      final pontos   = _decodePolyline(routes[0]['geometry'] as String);
      final duracaoS = (routes[0]['duration'] as num).toInt();
      final minutos  = (duracaoS / 60).ceil();

      if (mounted) {
        setState(() {
          _rotaCarregada  = true;
          _tempoEstimado  = '$minutos min';
          _polylines = {
            Polyline(
              polylineId: const PolylineId('rota_socorrista'),
              points: pontos,
              color: azulPrincipal,
              width: 5,
            ),
          };
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(_calcularBounds(), 80),
        );
      }
    } catch (_) {}
  }

  List<LatLng> _decodePolyline(String encoded) {
    final result = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result0 = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result0 |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
      shift = 0; result0 = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result0 |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
      result.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return result;
  }

  LatLngBounds _calcularBounds() {
    final lats = [
      widget.coordenadaSocorrista.latitude,
      widget.chamado.coordenadaUsuario.latitude,
    ];
    final lngs = [
      widget.coordenadaSocorrista.longitude,
      widget.chamado.coordenadaUsuario.longitude,
    ];
    return LatLngBounds(
      southwest: LatLng(lats.reduce((a, b) => a < b ? a : b) - 0.005,
                        lngs.reduce((a, b) => a < b ? a : b) - 0.005),
      northeast: LatLng(lats.reduce((a, b) => a > b ? a : b) + 0.005,
                        lngs.reduce((a, b) => a > b ? a : b) + 0.005),
    );
  }

  // ─── Avançar status ───────────────────────
  void _avancarStatus() {
    if (_statusIndex >= _statusList.length - 1) return;

    if (_statusIndex == _statusList.length - 2) {
      // Confirmar conclusão
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _ModalConcluir(
          nomeUsuario: widget.chamado.nomeUsuario,
          onConfirmar: () {
            Navigator.pop(context);
            setState(() => _statusIndex++);
            // TODO: chamar API para marcar como concluído
          },
        ),
      );
      return;
    }

    setState(() => _statusIndex++);
    // TODO: chamar API PUT /chamados/:id/status
  }

  // ─── Build ────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final alturaTela      = MediaQuery.of(context).size.height;
    final paddingMapa     = alturaTela * _painelInicial;
    final statusAtual     = _statusList[_statusIndex];
    final concluido       = _statusIndex == _statusList.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // ── Mapa ────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.coordenadaSocorrista,
              zoom: 13,
            ),
            markers:   _markers,
            polylines: _polylines,
            onMapCreated: (c) => _mapController = c,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            padding: EdgeInsets.only(bottom: paddingMapa),
          ),

          // ── Botão voltar ────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: pretoPrincipal, size: 20),
                ),
              ),
            ),
          ),

          // ── Centralizar mapa ────────────────
          Positioned(
            top: 72,
            right: 16,
            child: GestureDetector(
              onTap: () => _mapController?.animateCamera(
                CameraUpdate.newLatLngBounds(_calcularBounds(), 80),
              ),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.center_focus_strong_rounded,
                    color: pretoPrincipal, size: 20),
              ),
            ),
          ),

          // ── Painel deslizante ───────────────
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: _painelInicial,
            minChildSize: 0.15,
            maxChildSize: _painelExpandido,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40, height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // ── ETA + distância ─────────
                    Row(children: [
                      const Text('PREVISÃO',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: azulPrincipal,
                              fontSize: 12)),
                      const Spacer(),
                      const Text('Distância',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: azulPrincipal,
                              fontSize: 12)),
                    ]),
                    Row(children: [
                      Text(
                        _rotaCarregada ? _tempoEstimado : '...',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF042946)),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.chamado.distanciaKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF042946)),
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // ── Card escuro usuário ──────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardEscuro,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white24, width: 2),
                              color: Colors.white24,
                            ),
                            child: const Icon(Icons.person,
                                color: Colors.white54, size: 28),
                          ),

                          const SizedBox(width: 14),

                          // Dados
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.chamado.nomeUsuario,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.chamado.servico,
                                  style: const TextStyle(
                                      fontSize: 13, color: cinzaTexto),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.chamado.enderecoUsuario,
                                  style: const TextStyle(
                                      fontSize: 12, color: cinzaTexto),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Badge status
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusAtual.cor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusAtual.label,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: statusAtual.cor,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Stepper de status ────────
                    _buildStepper(),

                    const SizedBox(height: 20),

                    // ── Botões ligar / mensagem ──
                    Row(children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.phone_outlined, size: 18),
                          label: const Text('Ligar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C44AC),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                            elevation: 0,
                          ),
                          onPressed: () {}, // TODO: url_launcher tel:
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline,
                              size: 18),
                          label: const Text('Mensagem'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C44AC),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                            elevation: 0,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // ── Botão de ação principal ──
                    if (!concluido)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _avancarStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusAtual.cor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                            elevation: 0,
                          ),
                          child: Text(
                            _labelBotaoAvancar(),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),

                    // ── Tela de conclusão ────────
                    if (concluido) _buildConcluido(),

                    const SizedBox(height: 12),

                    // Cancelar (antes de concluir)
                    if (!concluido)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.grey),
                        child: const Text('Cancelar atendimento',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Stepper visual ───────────────────────
  Widget _buildStepper() {
    return Row(
      children: List.generate(_statusList.length, (i) {
        final ativo     = i == _statusIndex;
        final concluido = i < _statusIndex;
        final info      = _statusList[i];

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: ativo ? 36 : 28,
                      height: ativo ? 36 : 28,
                      decoration: BoxDecoration(
                        color: concluido
                            ? verdeStatus
                            : ativo
                                ? info.cor
                                : const Color(0xFFEEEEEE),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        concluido ? Icons.check_rounded : info.icone,
                        size: ativo ? 18 : 14,
                        color: (ativo || concluido)
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: ativo
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: ativo ? info.cor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < _statusList.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: i < _statusIndex
                        ? verdeStatus
                        : const Color(0xFFEEEEEE),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ─── Tela de conclusão ────────────────────
  Widget _buildConcluido() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: verdeStatus.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: verdeStatus.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: verdeStatus, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Atendimento concluído!',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: pretoPrincipal)),
                    const SizedBox(height: 2),
                    Text(
                      'Aguarde a avaliação de ${widget.chamado.nomeUsuario.split(' ').first}.',
                      style: const TextStyle(
                          fontSize: 13, color: cinzaTexto),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: pretoPrincipal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            child: const Text('Voltar para início',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  String _labelBotaoAvancar() {
    switch (_statusIndex) {
      case 0: return 'Cheguei ao local';
      case 1: return 'Iniciar atendimento';
      case 2: return 'Finalizar atendimento';
      default: return '';
    }
  }
}

// ─────────────────────────────────────────────
//  Modal de confirmação de conclusão
// ─────────────────────────────────────────────
class _ModalConcluir extends StatelessWidget {
  final String nomeUsuario;
  final VoidCallback onConfirmar;

  static const Color azulPrincipal  = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto     = Color(0xFF8A8A8A);

  const _ModalConcluir({
    required this.nomeUsuario,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Finalizar atendimento?',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: pretoPrincipal)),
          const SizedBox(height: 6),
          Text(
            'Confirme apenas se o serviço prestado a $nomeUsuario foi concluído.',
            style: const TextStyle(fontSize: 14, color: cinzaTexto),
          ),

          const SizedBox(height: 24),

          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cinzaTexto,
                  side: const BorderSide(color: Color(0xFFDDDDDD)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Voltar',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onConfirmar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Confirmar conclusão',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Modelo de status
// ─────────────────────────────────────────────
class _StatusInfo {
  final String   label;
  final IconData icone;
  final Color    cor;
  const _StatusInfo(this.label, this.icone, this.cor);
}