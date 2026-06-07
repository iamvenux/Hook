import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'overlay_endereco.dart';

// ─────────────────────────────────────────────
// Tela 1 — Resumo do Serviço
// ─────────────────────────────────────────────
class ResumoServicoScreen extends StatefulWidget {
  final String endereco;
  final LatLng coordenada;
  final String tipoReboque;
  final String veiculo;

  const ResumoServicoScreen({
    super.key,
    required this.endereco,
    required this.coordenada,
    required this.tipoReboque,
    required this.veiculo,
  });

  @override
  State<ResumoServicoScreen> createState() => _ResumoServicoScreenState();
}

class _ResumoServicoScreenState extends State<ResumoServicoScreen> {
  static const Color azulPrincipal  = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto     = Color(0xFF8A8A8A);
  static const Color cinzaFundo     = Color(0xFFF5F5F5);

  String _formaPagamento = 'Pix';
  late String _endereco;
  late LatLng _coordenada;

  @override
  void initState() {
    super.initState();
    _endereco   = widget.endereco;
    _coordenada = widget.coordenada;
  }

  final Map<String, String> _formasPagamento = {
    'Pix':              'Pagamento instantâneo',
    'Cartão de Crédito':'Visa, Master, Elo',
    'Cartão de Débito': 'Débito à vista',
    'Dinheiro':         'Pagamento em espécie',
  };

  String get _valorEstimado =>
      widget.tipoReboque == 'Guincho Pesado' ? 'R\$ 550,00' : 'R\$ 350,00';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _coordenada, zoom: 14),
            markers: {
              Marker(
                markerId: const MarkerId('encontro'),
                position: _coordenada,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

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
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.arrow_back, color: pretoPrincipal, size: 20),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RESUMO DO SERVIÇO',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: pretoPrincipal, letterSpacing: 0.3)),
                  const SizedBox(height: 16),

                  // Ponto de encontro
                  GestureDetector(
                    onTap: () async {
                      final resultado = await showGeneralDialog<dynamic>(
                        context: context,
                        barrierDismissible: false,
                        barrierColor: Colors.transparent,
                        transitionDuration: Duration.zero,
                        pageBuilder: (_, __, ___) => EnderecoOverlay(
                          enderecoAtual: _endereco,
                          coordenadaAtual: _coordenada,
                        ),
                      );
                      if (resultado != null && mounted) {
                        final r = resultado as Map<String, dynamic>;
                        setState(() {
                          _endereco   = r['endereco'] as String;
                          _coordenada = LatLng(r['lat'] as double, r['lng'] as double);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, decoration: const BoxDecoration(color: pretoPrincipal, shape: BoxShape.circle)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('PONTO DE ENCONTRO',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: azulPrincipal, letterSpacing: 0.8)),
                              const SizedBox(height: 3),
                              Text(_endereco, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: pretoPrincipal)),
                            ]),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: azulPrincipal.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: const Text('Alterar', style: TextStyle(color: azulPrincipal, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Valor estimado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Valor estimado', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: pretoPrincipal)),
                            const SizedBox(height: 3),
                            const Text('Pode variar conforme distância\ne tempo de espera',
                                style: TextStyle(fontSize: 11, color: cinzaTexto)),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_valorEstimado,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: azulPrincipal)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Pagamento
                  GestureDetector(
                    onTap: () => _mostrarAlterarPagamento(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: azulPrincipal.withOpacity(0.3), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: cinzaFundo, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.payment_rounded, color: pretoPrincipal, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_formaPagamento,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: pretoPrincipal)),
                              Text(_formasPagamento[_formaPagamento]!,
                                  style: const TextStyle(fontSize: 12, color: cinzaTexto)),
                            ]),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(color: azulPrincipal.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: const Text('Alterar', style: TextStyle(color: azulPrincipal, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProcurandoMotoristaScreen(
                                  endereco: _endereco,
                                  coordenada: _coordenada,
                                  tipoReboque: widget.tipoReboque,
                                  veiculo: widget.veiculo,
                                  valorEstimado: _valorEstimado,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pretoPrincipal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            elevation: 0,
                          ),
                          child: const Text('Solicitar guincho',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarAlterarPagamento(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Forma de pagamento',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 16),
              ..._formasPagamento.entries.map((e) {
                final selecionado = _formaPagamento == e.key;
                return GestureDetector(
                  onTap: () {
                    setState(() => _formaPagamento = e.key);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selecionado ? azulPrincipal.withOpacity(0.07) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selecionado ? azulPrincipal : Colors.transparent, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.key,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: selecionado ? azulPrincipal : const Color(0xFF1A1A1A))),
                            Text(e.value, style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A))),
                          ]),
                        ),
                        if (selecionado)
                          const Icon(Icons.check_circle_rounded, color: azulPrincipal, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Tela 2 — Procurando / Acompanhando Motorista
// ─────────────────────────────────────────────
class ProcurandoMotoristaScreen extends StatefulWidget {
  final String endereco;
  final LatLng coordenada;
  final String tipoReboque;
  final String veiculo;
  final String valorEstimado;

  const ProcurandoMotoristaScreen({
    super.key,
    required this.endereco,
    required this.coordenada,
    required this.tipoReboque,
    required this.veiculo,
    required this.valorEstimado,
  });

  @override
  State<ProcurandoMotoristaScreen> createState() =>
      _ProcurandoMotoristaScreenState();
}

class _ProcurandoMotoristaScreenState extends State<ProcurandoMotoristaScreen>
    with SingleTickerProviderStateMixin {
  static const Color azulPrincipal  = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto     = Color(0xFF9CB1C9);
  static const Color cardEscuro     = Color(0xFF1C2C3E);

  late AnimationController _progressController;
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final double _tamanhoAceitePainel  = 0.82;
  late Animation<double>   _progressAnim;
  Timer?                   _buscaTimer;
  GoogleMapController?     _mapController;

  final double _tamanhoInicialPainel = 0.60;

  final List<Map<String, dynamic>> _motoristasProximos = [
    {
      'nome': 'Ricardo',
      'distancia': '1.2 km',
      'avaliacao': '4.9',
      'coordenada': null,
      'veiculo': 'Caminhão Guincho Ford',
      'placa': 'ABC-1234',
      'foto': 'assets/image/Ricardo.png',
      'tempo': '12 min',
    },
    {
      'nome': 'João Pereira',
      'distancia': '2.8 km',
      'avaliacao': '4.7',
      'coordenada': null,
      'veiculo': 'Iveco Daily',
      'placa': 'DEF-5678',
      'foto': null,
      'tempo': '8 min',
    },
    {
      'nome': 'Marcos Souza',
      'distancia': '3.5 km',
      'avaliacao': '4.8',
      'coordenada': null,
      'veiculo': 'Ford Cargo',
      'placa': 'GHI-9012',
      'foto': null,
      'tempo': '11 min',
    },
  ];

  Set<Marker>   _markers   = {};
  Set<Polyline> _polylines = {};
  bool _motoristasVisiveis = false;
  bool _motoristaAceitou   = false;

  @override
  void initState() {
    super.initState();

    _motoristasProximos[0]['coordenada'] = LatLng(
      widget.coordenada.latitude  + 0.011,
      widget.coordenada.longitude - 0.008,
    );
    _motoristasProximos[1]['coordenada'] = LatLng(
      widget.coordenada.latitude  - 0.020,
      widget.coordenada.longitude + 0.015,
    );
    _motoristasProximos[2]['coordenada'] = LatLng(
      widget.coordenada.latitude  + 0.025,
      widget.coordenada.longitude + 0.020,
    );

    _markers.add(Marker(
      markerId: const MarkerId('encontro'),
      position: widget.coordenada,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _progressAnim = CurvedAnimation(parent: _progressController, curve: Curves.easeInOut);
    _progressController.forward();

    _progressController.addStatusListener((status) async {
      if (status == AnimationStatus.completed && mounted) {
        final maisProximo = _motoristasProximos[0];
        final icone = await _criarIconeCarro();
        if (!mounted) return;
        setState(() {
          _motoristasVisiveis = true;
          _markers.add(Marker(
            markerId: MarkerId(maisProximo['nome'] as String),
            position: maisProximo['coordenada'] as LatLng,
            icon: icone,
            infoWindow: InfoWindow(
              title: maisProximo['nome'] as String,
              snippet: '${maisProximo['distancia']} • ${maisProximo['tempo']}',
            ),
          ));
        });

        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(_calcularBounds(), 80));

        _buscaTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _motoristaAceitou = true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _sheetController.animateTo(_tamanhoAceitePainel,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut);
            });
            _buscarRota(maisProximo['coordenada'] as LatLng, widget.coordenada);
          }
        });
      }
    });
  }

  Future<void> _buscarRota(LatLng origem, LatLng destino) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origem.longitude},${origem.latitude};'
      '${destino.longitude},${destino.latitude}'
      '?overview=full&geometries=polyline',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return;
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return;
      final routes = data['routes'] as List;
      if (routes.isEmpty) return;
      final pontos = _decodePolyline(routes[0]['geometry'] as String);
      if (mounted) {
        setState(() {
          _polylines.add(Polyline(
            polylineId: const PolylineId('rota_motorista'),
            points: pontos,
            color: azulPrincipal,
            width: 5,
          ));
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(_calcularBounds(), 80));
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

  Future<BitmapDescriptor> _criarIconeCarro() async {
    const size = 80.0;
    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, Paint()..color = azulPrincipal);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 2,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 4);
    final branco = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndCorners(const Rect.fromLTWH(12, 34, 56, 22),
          topLeft: const Radius.circular(4), topRight: const Radius.circular(4),
          bottomLeft: const Radius.circular(3), bottomRight: const Radius.circular(3)),
      branco,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(const Rect.fromLTWH(20, 24, 38, 14),
          topLeft: const Radius.circular(6), topRight: const Radius.circular(6)),
      branco,
    );
    canvas.drawCircle(const Offset(24, 57), 7, branco);
    canvas.drawCircle(const Offset(24, 57), 4, Paint()..color = azulPrincipal);
    canvas.drawCircle(const Offset(56, 57), 7, branco);
    canvas.drawCircle(const Offset(56, 57), 4, Paint()..color = azulPrincipal);
    final picture = recorder.endRecording();
    final img  = await picture.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  LatLngBounds _calcularBounds() {
    double minLat = widget.coordenada.latitude,  maxLat = widget.coordenada.latitude;
    double minLng = widget.coordenada.longitude, maxLng = widget.coordenada.longitude;
    for (final m in _motoristasProximos) {
      final pos = m['coordenada'] as LatLng;
      if (pos.latitude  < minLat) minLat = pos.latitude;
      if (pos.latitude  > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat - 0.005, minLng - 0.005),
      northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _buscaTimer?.cancel();
    _sheetController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alturaTela          = MediaQuery.of(context).size.height;
    final paddingInferiorMapa = alturaTela * _tamanhoInicialPainel;
    final motorista           = _motoristasProximos[0];

    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            initialCameraPosition: CameraPosition(target: widget.coordenada, zoom: 13),
            markers:   _markers,
            polylines: _polylines,
            onMapCreated: (c) => _mapController = c,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            padding: EdgeInsets.only(bottom: paddingInferiorMapa),
          ),

          // Botão voltar
          Positioned(
            bottom: paddingInferiorMapa + 190,
            left: 20,
            child: FloatingActionButton(
              heroTag: 'btn_back',
              backgroundColor: Colors.white,
              elevation: 2,
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back, color: pretoPrincipal),
            ),
          ),



          // Painel deslizante
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: _tamanhoInicialPainel,
            minChildSize: 0.15,
            maxChildSize: _tamanhoAceitePainel,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 5)],
                ),
                child: AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (context, _) {
                    final progresso  = _progressAnim.value;
                    final percentual = (progresso * 100).toInt();

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      children: [
                        // Handle
                        Center(
                          child: Container(
                            width: 40, height: 5,
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                        // Título
                        Text(
                          _motoristaAceitou
                              ? 'Seu guincho parceiro está a caminho'
                              : _motoristasVisiveis
                                  ? 'Motorista encontrado!'
                                  : 'Procurando o motorista mais próximo...',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: pretoPrincipal),
                        ),
                        const SizedBox(height: 16),

                        // ETA + Distância
                        if (_motoristaAceitou) ...[
                          Row(children: [
                            const Text('PREVISÃO',
                                style: TextStyle(fontWeight: FontWeight.bold, color: azulPrincipal, fontSize: 12)),
                            const Spacer(),
                            const Text('Distância',
                                style: TextStyle(fontWeight: FontWeight.bold, color: azulPrincipal, fontSize: 12)),
                          ]),
                          Row(children: [
                            Text(motorista['tempo'] as String,
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF042946))),
                            const Spacer(),
                            Text(motorista['distancia'] as String,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF042946))),
                          ]),
                          const SizedBox(height: 10),
                        ],

                        // Barra de progresso
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _motoristaAceitou ? null : progresso,
                            minHeight: 9,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(azulPrincipal),
                          ),
                        ),

                        if (!_motoristaAceitou) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _motoristasVisiveis ? 'Aguardando confirmação...' : 'Buscando em raio de 5 km',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text('$percentual%',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                            ],
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Card escuro do motorista — só aparece após aceite
                        if (_motoristaAceitou)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: cardEscuro, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              // Avatar com nota
                              Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 56, height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24, width: 2),
                                      image: motorista['foto'] != null
                                          ? DecorationImage(
                                              image: AssetImage(motorista['foto'] as String),
                                              fit: BoxFit.cover)
                                          : null,
                                      color: motorista['foto'] == null ? Colors.white24 : null,
                                    ),
                                    child: motorista['foto'] == null
                                        ? const Icon(Icons.person, color: Colors.white54, size: 28)
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: -8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, spreadRadius: 1)],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(motorista['avaliacao'] as String,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.star_border, color: Colors.cyanAccent, size: 14),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // Dados
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(motorista['nome'] as String,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 2),
                                    Text(motorista['veiculo'] as String,
                                        style: const TextStyle(fontSize: 13, color: cinzaTexto, height: 1.3)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(164, 36, 94, 145),
                                        border: Border.all(color: const Color.fromARGB(255, 36, 94, 145)),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(motorista['placa'] as String,
                                          style: const TextStyle(fontSize: 12, color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                              // Valor + status
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(widget.valorEstimado,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                                  const Text('ESTIMADO',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: azulPrincipal, letterSpacing: 0.5)),
                                  const SizedBox(height: 6),
                                  if (_motoristaAceitou)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text('A caminho',
                                          style: TextStyle(fontSize: 11, color: Colors.greenAccent)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Botões Mensagem / Ligar
                        if (_motoristaAceitou) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                  label: const Text('Mensagem'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0C44AC),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    elevation: 0,
                                  ),
                                  onPressed: () {},
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.phone_outlined, size: 18),
                                  label: const Text('Ligar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0C44AC),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    elevation: 0,
                                  ),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Botão cancelar (antes do aceite)
                        if (!_motoristaAceitou)
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: pretoPrincipal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                elevation: 0,
                              ),
                              child: const Text('Cancelar solicitação',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ),
                          ),

                        // Link cancelar (após aceite)
                        if (_motoristaAceitou)
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(foregroundColor: Colors.grey),
                            child: const Text('Cancelar Pedido',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),

                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}