import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'api_service.dart';
import 'avaliacao_screen.dart';
import 'chat_solicitacao_screen.dart';
import 'icone_carro.dart';
import 'perfil_componentes.dart';

class ChamadoAceito {
  final int id;
  final String nomeUsuario;
  final String? fotoUsuario;
  final String servico;
  final LatLng coordenadaUsuario;
  final String enderecoUsuario;
  final double distanciaKm;

  const ChamadoAceito({
    required this.id,
    required this.nomeUsuario,
    this.fotoUsuario,
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
  // ── Cores ──
  static const Color azulPrincipal  = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto     = Color(0xFF8A8A8A);
  static const Color cinzaFundo     = Color(0xFFF5F5F5);
  static const Color verdeStatus    = Color(0xFF22C55E);
  static const Color vermelho       = Color(0xFFEF4444);

  // ── Status do atendimento ─────────────────
  // 0 = a caminho | 1 = no local | 2 = em atendimento | 3 = concluído
  int _statusIndex = 0;

  static const List<String> _rotulos = [
    'A caminho',
    'No local',
    'Em atendimento',
    'Concluído',
  ];

  static const List<String> _titulos = [
    'Indo até o cliente',
    'Você chegou ao local',
    'Atendimento em andamento',
    'Atendimento concluído',
  ];

  // ── Mapa ──────────────────────────────────
  GoogleMapController?  _mapController;
  Set<Marker>           _markers   = {};
  Set<Polyline>         _polylines = {};

  BitmapDescriptor? _iconeSocorrista;

  // ── Painel ────────────────────────────────
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  static const double _painelInicial = 0.40;
  static const double _painelExpandido = 0.72;

  // ── Rota e simulação do trajeto ───────────
  // Protótipo: o motorista não se desloca de verdade. O carro percorre a
  // rota desenhada em 25 passos, um a cada 2 segundos (~50 s no total), e
  // cada passo envia a posição ao servidor, então o cliente acompanha.
  static const int _passosSim = 25;

  bool _avaliado = false;

  List<LatLng> _rota = [];
  List<double> _acumulado = [];
  double _comprimentoKm = 0;

  int  _passo = 0;
  bool _chegouAoCliente = false;
  int  _minutosTotais = 0;

  late LatLng _origem;
  late LatLng _posSocorrista;
  Timer? _simTimer;

  BitmapDescriptor? _iconeCliente;

  /// Coordenada do cliente, só quando o cadastro tem uma válida.
  /// (0,0) ou valor fora de faixa = solicitação sem localização.
  LatLng? get _cliente {
    final c = widget.chamado.coordenadaUsuario;

    final valida = c.latitude.isFinite &&
        c.longitude.isFinite &&
        c.latitude.abs() > 0.01 &&
        c.longitude.abs() > 0.01 &&
        c.latitude.abs() <= 90 &&
        c.longitude.abs() <= 180;

    return valida ? c : null;
  }

  // O app é um protótipo: o motorista pode estar longe do cliente (o GPS
  // do emulador fica nos EUA) ou no mesmo lugar que ele. Fora da faixa
  // abaixo, a simulação começa num ponto a ~1,8 km do cliente.
  static const double _limiteKm = 25;
  static const double _minimoKm = 0.8;

  static double _kmEntre(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(a.latitude * math.pi / 180) *
            math.cos(b.latitude * math.pi / 180) *
            math.pow(math.sin(dLng / 2), 2);

    final s = math.sqrt(h.toDouble().clamp(0.0, 1.0));

    return 2 * r * math.asin(s);
  }

  @override
  void initState() {
    super.initState();

    final cliente = _cliente;

    if (cliente == null) {
      // Sem localização do cliente não há trajeto para simular.
      _origem = widget.coordenadaSocorrista;
      _posSocorrista = _origem;
      _chegouAoCliente = true;
      _carregarIcones();

      return;
    }

    final dist = _kmEntre(widget.coordenadaSocorrista, cliente);

    _origem = (dist > _limiteKm || dist < _minimoKm)
        ? _pontoProximo(cliente)
        : widget.coordenadaSocorrista;

    _posSocorrista = _origem;

    // Já começa com a rota em linha reta, para o carro andar mesmo sem
    // internet. A rota pelas ruas entra no lugar dela quando chegar.
    _definirRota(_linhaReta(_origem, cliente), desenhar: false);

    _carregarIcones();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _iniciarSimulacao();
    });

    _buscarRota();
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _sheetController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Ponto de partida artificial, a ~1,8 km do cliente.
  static LatLng _pontoProximo(LatLng cliente) => LatLng(
        cliente.latitude + 0.012,
        cliente.longitude - 0.010,
      );

  static List<LatLng> _linhaReta(LatLng a, LatLng b) {
    const n = 40;

    return List<LatLng>.generate(n + 1, (i) {
      final t = i / n;

      return LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
    });
  }

  // ─── Ícones ───────────────────────────────
  Future<void> _carregarIcones() async {
    final pin = await _criarIconePin(Colors.red);
    final carro = await criarIconeCarro();

    if (!mounted) return;

    _iconeCliente = pin;
    _iconeSocorrista = carro;

    _desenhar();
  }

  Marker _marcadorSocorrista(LatLng pos) {
    return Marker(
      markerId: const MarkerId('socorrista'),
      position: pos,
      icon: _iconeSocorrista ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      anchor: const Offset(0.5, 0.5),
      infoWindow: const InfoWindow(title: 'Você'),
    );
  }

  // ─── Ícone pin vermelho (cliente) ─────────
  Future<BitmapDescriptor> _criarIconePin(Color cor) async {
    const size = 80.0;
    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);
    final paint    = Paint()..color = cor;

    canvas.drawCircle(const Offset(size / 2, size / 2 - 10), 22, paint);

    final path = Path()
      ..moveTo(size / 2 - 10, size / 2 + 10)
      ..lineTo(size / 2 + 10, size / 2 + 10)
      ..lineTo(size / 2, size / 2 + 30)
      ..close();

    canvas.drawPath(path, paint);

    canvas.drawCircle(
      const Offset(size / 2, size / 2 - 10), 12,
      Paint()..color = Colors.white,
    );

    final picture = recorder.endRecording();
    final img     = await picture.toImage(size.toInt(), (size * 0.9).toInt());
    final data    = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // ─── Rota pelas ruas (OSRM) ───────────────
  Future<void> _buscarRota() async {
    final cliente = _cliente;

    if (cliente == null) return;

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${_origem.longitude},${_origem.latitude};'
      '${cliente.longitude},${cliente.latitude}'
      '?overview=full&geometries=polyline',
    );

    try {
      final response = await http.get(url).timeout(
            const Duration(seconds: 12),
          );

      if (!mounted || response.statusCode != 200) return;

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data['code'] != 'Ok') return;

      final routes = data['routes'] as List;

      if (routes.isEmpty) return;

      final pontos = _decodePolyline(routes[0]['geometry'] as String);

      if (pontos.length < 2) return;

      final duracaoS = (routes[0]['duration'] as num?)?.toInt() ?? 0;

      if (duracaoS > 0) _minutosTotais = (duracaoS / 60).ceil();

      // Troca a linha reta pela rota de ruas sem perder o progresso.
      _definirRota(pontos);

      _enquadrarMapa();
    } catch (_) {
      // Sem rota de ruas: a linha reta já está valendo.
    }
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

  // ─── Monta a rota usada pela simulação ────
  void _definirRota(
    List<LatLng> pontos, {
    bool desenhar = true,
    bool jaAjustou = false,
  }) {
    final cliente = _cliente;

    if (cliente == null) return;

    // Pontos repetidos zeram o comprimento da rota (e travavam a
    // simulação): ficam de fora.
    final limpos = <LatLng>[];

    for (final p in pontos) {
      if (!p.latitude.isFinite || !p.longitude.isFinite) continue;

      if (limpos.isEmpty || _kmEntre(limpos.last, p) > 0.0005) {
        limpos.add(p);
      }
    }

    // A rota tem que terminar no cliente.
    if (limpos.isEmpty || _kmEntre(limpos.last, cliente) > 0.03) {
      limpos.add(cliente);
    }

    final acum = <double>[0];

    for (var i = 1; i < limpos.length; i++) {
      acum.add(acum.last + _kmEntre(limpos[i - 1], limpos[i]));
    }

    final total = acum.last;

    // Trajeto curto demais (origem praticamente sobre o cliente):
    // afasta o ponto de partida para haver percurso.
    if (!total.isFinite || total <= 0.05) {
      if (jaAjustou) return;

      _origem = _pontoProximo(cliente);

      _definirRota(
        _linhaReta(_origem, cliente),
        desenhar: desenhar,
        jaAjustou: true,
      );

      return;
    }

    _rota = limpos;
    _acumulado = acum;
    _comprimentoKm = total;

    if (_minutosTotais <= 0) {
      _minutosTotais = math.max((total / 30 * 60).ceil(), 1);
    }

    if (desenhar) _desenhar();
  }

  /// Ponto da rota a [km] do início, com o índice do próximo vértice.
  (LatLng, int) _pontoEm(double km) {
    if (_rota.length < 2) return (_origem, _rota.length);

    if (km <= 0) return (_rota.first, 1);

    if (km >= _comprimentoKm) return (_rota.last, _rota.length);

    var i = 1;

    while (i < _acumulado.length && _acumulado[i] < km) {
      i++;
    }

    final ini = _acumulado[i - 1];
    final seg = _acumulado[i] - ini;
    final t = seg <= 0 ? 0.0 : (km - ini) / seg;

    final a = _rota[i - 1];
    final b = _rota[i];

    return (
      LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      ),
      i,
    );
  }

  // ─── Desenho do mapa ──────────────────────
  // Marcadores e linha são refeitos do zero a cada passo, a partir da
  // rota e do progresso. Nada depende do que estava desenhado antes.
  void _desenhar({bool enviar = false}) {
    if (!mounted) return;

    final cliente = _cliente;
    final fracao = (_passo / _passosSim).clamp(0.0, 1.0);

    var pos = _posSocorrista;
    var resto = <LatLng>[];

    if (_statusIndex > 0 && cliente != null) {
      // Já chegou: o carro fica sobre o cliente.
      pos = cliente;
    } else if (_comprimentoKm > 0 && _rota.length >= 2) {
      final (p, i) = _pontoEm(_comprimentoKm * fracao);

      pos = p;
      resto = _rota.sublist(math.min(i, _rota.length));
    }

    setState(() {
      _posSocorrista = pos;

      _markers = {
        if (cliente != null)
          Marker(
            markerId: const MarkerId('usuario'),
            position: cliente,
            icon: _iconeCliente ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
            infoWindow: InfoWindow(
              title: widget.chamado.nomeUsuario,
              snippet: widget.chamado.enderecoUsuario,
            ),
          ),
        _marcadorSocorrista(pos),
      };

      if (cliente == null || _rota.length < 2) {
        _polylines = {};
      } else {
        final percorrido = resto.isEmpty;

        _polylines = {
          Polyline(
            polylineId: const PolylineId('rota_socorrista'),
            points: percorrido ? _rota : [pos, ...resto],
            color: percorrido
                ? azulPrincipal.withValues(alpha: 0.35)
                : azulPrincipal,
            width: 5,
          ),
        };
      }
    });

    if (enviar) _enviarPosicao(pos);
  }

  void _enquadrarMapa() {
    final bounds = _calcularBounds();

    if (bounds == null) return;

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  LatLngBounds? _calcularBounds() {
    final cliente = _cliente;

    if (cliente == null) return null;

    final pontos = _rota.length >= 2 ? _rota : [_origem, cliente];

    var sulLat = pontos.first.latitude;
    var norLat = pontos.first.latitude;
    var oesLng = pontos.first.longitude;
    var lesLng = pontos.first.longitude;

    for (final p in pontos) {
      sulLat = math.min(sulLat, p.latitude);
      norLat = math.max(norLat, p.latitude);
      oesLng = math.min(oesLng, p.longitude);
      lesLng = math.max(lesLng, p.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(sulLat - 0.004, oesLng - 0.004),
      northeast: LatLng(norLat + 0.004, lesLng + 0.004),
    );
  }

  // ─── Simulação ────────────────────────────
  void _iniciarSimulacao() {
    _simTimer?.cancel();

    _passo = 0;
    _chegouAoCliente = false;

    if (_cliente == null || _comprimentoKm <= 0) {
      setState(() => _chegouAoCliente = true);

      return;
    }

    // O cliente já vê o carro no ponto de partida.
    _desenhar(enviar: true);

    _enquadrarMapa();

    _simTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (!mounted || _statusIndex != 0) {
        t.cancel();

        return;
      }

      _passo++;

      _desenhar(enviar: true);

      if (_passo >= _passosSim) {
        t.cancel();

        if (mounted) setState(() => _chegouAoCliente = true);
      }
    });
  }

  int get _segundosRestantes => (_passosSim - _passo).clamp(0, _passosSim) * 2;

  Future<void> _enviarPosicao(LatLng pos) async {
    try {
      await ApiService.instance.atualizarLocalizacao(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } catch (_) {
      // sem rede por um instante: a próxima atualização corrige
    }
  }

  /// "4 min" restantes, proporcional ao trecho já percorrido.
  String get _tempoRestante {
    if (_comprimentoKm <= 0) return '--';

    if (_statusIndex > 0 || _chegouAoCliente) return 'Chegou';

    final fracao = (_passo / _passosSim).clamp(0.0, 1.0);

    final min = (_minutosTotais * (1 - fracao)).ceil();

    return '${math.max(min, 1)} min';
  }

  String get _distanciaRestante {
    if (_statusIndex > 0 || _chegouAoCliente) return '0,0 km';

    final fracao = (_passo / _passosSim).clamp(0.0, 1.0);

    final km = _comprimentoKm * (1 - fracao);

    return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  void _centralizar() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _posSocorrista, zoom: 16),
      ),
    );
  }

  // ─── Avançar status ───────────────────────
  Future<void> _avancarStatus() async {
    if (_statusIndex >= _rotulos.length - 1) return;

    // "Cheguei" só depois que o carro chegou até o cliente.
    if (_statusIndex == 0 && !_chegouAoCliente) return;

    final proximoIndex = _statusIndex + 1;

    const statusBackend = [
      'a_caminho',
      'no_local',
      'em_atendimento',
      'concluido',
    ];

    try {
      await ApiService.instance.atualizarStatus(
        solicitacaoId: widget.chamado.id,
        status: statusBackend[proximoIndex],
      );

      if (!mounted) return;

      // "Cheguei": o carro para em cima do cliente.
      if (proximoIndex == 1) {
        _simTimer?.cancel();

        setState(() => _statusIndex = proximoIndex);

        _desenhar(enviar: true);
      } else {
        setState(() {
          _statusIndex = proximoIndex;
        });

        // Concluiu: já abre a avaliação do cliente.
        if (proximoIndex == _rotulos.length - 1) {
          _abrirAvaliacao();
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem)),
      );
    }
  }

  Future<void> _abrirAvaliacao() async {
    if (!mounted) return;

    final enviou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AvaliacaoScreen(
          solicitacaoId: widget.chamado.id,
          nomeAvaliado: widget.chamado.nomeUsuario,
          fotoAvaliado: widget.chamado.fotoUsuario,
          avaliadorMotorista: true,
        ),
      ),
    );

    if (enviou == true && mounted) {
      _simTimer?.cancel();

      // Avaliou: volta para o início do motorista.
      Navigator.of(context).pop();
    }
  }

  // ─── Cancelar ─────────────────────────────
  Future<void> _cancelar() async {
    final confirmar = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: vermelho.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: vermelho, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cancelar atendimento?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: pretoPrincipal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A solicitação também será cancelada para o cliente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: cinzaTexto,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pretoPrincipal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'Continuar atendimento',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Cancelar atendimento',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: vermelho,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.instance.atualizarStatus(
        solicitacaoId: widget.chamado.id,
        status: 'cancelado',
      );

      _simTimer?.cancel();

      if (!mounted) return;

      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem)),
      );
    }
  }

  void _abrirChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatSolicitacaoScreen(
          solicitacaoId: widget.chamado.id,
          titulo: widget.chamado.nomeUsuario,
          motorista: true,
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final alturaTela  = MediaQuery.of(context).size.height;
    final paddingMapa = alturaTela * _painelInicial;
    final concluido   = _statusIndex == _rotulos.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Mapa ────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _origem,
              zoom: 13,
            ),
            markers:   _markers,
            polylines: _polylines,
            onMapCreated: (c) {
              _mapController = c;

              _enquadrarMapa();
            },
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            padding: EdgeInsets.only(bottom: paddingMapa),
            // O mapa tem prioridade nos gestos (zoom com dois dedos).
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
          ),

          // ── Único botão sobre o mapa: centralizar ──
          AnimatedBuilder(
            animation: _sheetController,
            builder: (context, _) {
              final fracao = _sheetController.isAttached
                  ? _sheetController.size
                  : _painelInicial;

              return Positioned(
                right: 16,
                bottom: alturaTela * math.min(fracao, 0.75) + 16,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _centralizar,
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(
                        Icons.my_location_rounded,
                        color: pretoPrincipal,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Painel deslizante ───────────────
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: _painelInicial,
            minChildSize: 0.18,
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
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDDDDD),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // ── Título + tempo ─────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _statusIndex == 0 && _chegouAoCliente
                                ? 'Você chegou ao cliente'
                                : _titulos[_statusIndex],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: pretoPrincipal,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (!concluido)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _tempoRestante,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: azulPrincipal,
                                ),
                              ),
                              Text(
                                _distanciaRestante,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: cinzaTexto,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── Linha de andamento (estilo Uber) ──
                    _buildProgresso(),

                    const SizedBox(height: 20),

                    // ── Cliente ─────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cinzaFundo,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          AvatarUsuario(
                            nome: widget.chamado.nomeUsuario,
                            fotoUrl: widget.chamado.fotoUsuario,
                            tamanho: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.chamado.nomeUsuario,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: pretoPrincipal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.chamado.servico,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: cinzaTexto,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: azulPrincipal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.chamado.enderecoUsuario,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              color: pretoPrincipal,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ── Mensagem ────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _abrirChat,
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Mensagem',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: pretoPrincipal,
                          side: const BorderSide(color: Color(0xFFDDDDDD)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Ação principal ──────────
                    if (!concluido)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: (_statusIndex == 0 && !_chegouAoCliente)
                              ? null
                              : _avancarStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pretoPrincipal,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFFDDDDDD),
                            disabledForegroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _labelBotaoAvancar(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                    if (_statusIndex == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _cliente == null
                              ? 'Esta solicitação não tem a localização do '
                                  'cliente. Combine o local pela mensagem.'
                              : _chegouAoCliente
                                  ? 'Você chegou: já pode marcar '
                                      '"Cheguei ao local".'
                                  : 'Seguindo pela rota · passo $_passo de '
                                      '$_passosSim · faltam '
                                      '${_segundosRestantes}s',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: cinzaTexto,
                          ),
                        ),
                      ),

                    if (concluido) _buildConcluido(),

                    if (!concluido)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: TextButton(
                          onPressed: _cancelar,
                          style: TextButton.styleFrom(
                            foregroundColor: cinzaTexto,
                          ),
                          child: const Text(
                            'Cancelar atendimento',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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

  // ─── Linha de andamento ───────────────────
  Widget _buildProgresso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(_rotulos.length, (i) {
            final feito = i <= _statusIndex;

            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(
                  right: i == _rotulos.length - 1 ? 0 : 4,
                ),
                decoration: BoxDecoration(
                  color: feito ? azulPrincipal : const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(_rotulos.length, (i) {
            final atual = i == _statusIndex;

            return Expanded(
              child: Text(
                _rotulos[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: atual ? FontWeight.w800 : FontWeight.w500,
                  color: atual ? pretoPrincipal : cinzaTexto,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─── Conclusão ────────────────────────────
  Widget _buildConcluido() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: verdeStatus.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: verdeStatus, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bom trabalho! Que tal avaliar '
                  '${widget.chamado.nomeUsuario.split(' ').first}?',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: pretoPrincipal,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!_avaliado) ...[
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _abrirAvaliacao,
              style: ElevatedButton.styleFrom(
                backgroundColor: azulPrincipal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Avaliar cliente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: pretoPrincipal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Voltar para o início',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
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
