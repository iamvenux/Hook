import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'busca_endereco.dart';
import 'enderecos_store.dart';
import 'salvar_endereco_dialog.dart';

const Color azulPrincipal = Color(0xFF1A7EF5);
const Color pretoPrincipal = Color(0xFF1A1A1A);
const Color cinzaTexto = Color(0xFF8A8A8A);
const Color cinzaFundo = Color(0xFFF5F5F5);

/// Resultado de uma busca de endereço.
class _Sugestao {
  final String titulo;
  final String subtitulo;
  final String endereco;
  final LatLng pos;

  const _Sugestao({
    required this.titulo,
    required this.subtitulo,
    required this.endereco,
    required this.pos,
  });
}

/// Monta as partes legíveis de um [Placemark].
List<String> _partesDoPlacemark(Placemark p) {
  String limpo(String? v) => (v ?? '').trim();

  final rua = [limpo(p.thoroughfare), limpo(p.subThoroughfare)]
      .where((e) => e.isNotEmpty)
      .join(', ');

  final partes = <String>[
    if (rua.isNotEmpty) rua,
    if (limpo(p.subLocality).isNotEmpty) limpo(p.subLocality),
    if (limpo(p.locality).isNotEmpty) limpo(p.locality),
  ];

  if (partes.isEmpty && limpo(p.name).isNotEmpty) {
    partes.add(limpo(p.name));
  }

  return partes;
}

String _enderecoDoPlacemark(Placemark p) =>
    _partesDoPlacemark(p).join(', ');

/// Tela (em tela cheia) para escolher o ponto de encontro:
/// busca com sugestões, endereços salvos, recentes e seleção no mapa.
///
/// Devolve `{'endereco': String, 'lat': double, 'lng': double}`.
class EnderecoOverlay extends StatefulWidget {
  final String enderecoAtual;
  final LatLng? coordenadaAtual;

  final String titulo;
  final String textoConfirmar;

  /// Quando true (cadastro de endereço salvo) não mostra salvos/recentes
  /// e não registra o ponto escolhido no histórico.
  final bool modoCadastro;

  const EnderecoOverlay({
    super.key,
    required this.enderecoAtual,
    this.coordenadaAtual,
    this.titulo = 'Ponto de encontro',
    this.textoConfirmar = 'Confirmar este ponto',
    this.modoCadastro = false,
  });

  @override
  State<EnderecoOverlay> createState() => _EnderecoOverlayState();
}

class _EnderecoOverlayState extends State<EnderecoOverlay> {
  static const LatLng _posicaoPadrao = LatLng(-23.5650, -46.6520);

  final _buscaController = TextEditingController();
  Timer? _debounce;

  List<_Sugestao> _sugestoes = [];
  bool _buscando = false;
  bool _consultaFeita = false;
  bool _erroBusca = false;

  List<EnderecoSalvo> _salvos = [];
  List<EnderecoRecente> _recentes = [];

  bool _modoMapa = false;
  late LatLng _pin;
  String _enderecoPin = '';
  bool _resolvendoPin = false;
  GoogleMapController? _mapController;

  bool get _temLocalizacaoAtual =>
      widget.coordenadaAtual != null &&
      widget.enderecoAtual.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    _pin = widget.coordenadaAtual ?? _posicaoPadrao;

    if (!widget.modoCadastro) {
      _carregarListas();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscaController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // DADOS
  // ------------------------------------------------------------

  Future<void> _carregarListas() async {
    final salvos = await EnderecosStore.listarSalvos();
    final recentes = await EnderecosStore.listarRecentes();

    if (!mounted) return;

    setState(() {
      _salvos = salvos;
      _recentes = recentes;
    });
  }

  // ------------------------------------------------------------
  // BUSCA
  // ------------------------------------------------------------

  void _onBuscaChanged(String texto) {
    _debounce?.cancel();

    final consulta = texto.trim();

    if (consulta.length < 4) {
      setState(() {
        _sugestoes = [];
        _buscando = false;
        _consultaFeita = false;
        _erroBusca = false;
      });
      return;
    }

    setState(() {
      _buscando = true;
      _erroBusca = false;
    });

    // Espera a pessoa parar de digitar (o serviço aceita ~1 consulta/s).
    _debounce = Timer(
      const Duration(milliseconds: 900),
      () => _buscar(consulta),
    );
  }

  Future<void> _buscar(String consulta) async {
    try {
      // Dá preferência ao que está perto de onde a pessoa está / do pin.
      final centro = widget.coordenadaAtual ?? _pin;

      final cidade = await _cidadeDe(centro);

      final achados = await BuscaEndereco.buscar(
        consulta,
        perto: (lat: centro.latitude, lng: centro.longitude),
        cidade: cidade,
      );

      if (!mounted || _buscaController.text.trim() != consulta) return;

      final vistos = <String>{};

      setState(() {
        _sugestoes = achados
            .map(
              (r) => _Sugestao(
                titulo: r.titulo,
                subtitulo: r.subtitulo,
                endereco: r.endereco,
                pos: LatLng(r.lat, r.lng),
              ),
            )
            .where((s) => vistos.add(s.endereco))
            .toList();
        _buscando = false;
        _consultaFeita = true;
        _erroBusca = false;
      });
    } catch (_) {
      if (!mounted || _buscaController.text.trim() != consulta) return;

      setState(() {
        _sugestoes = [];
        _buscando = false;
        _consultaFeita = true;
        _erroBusca = true;
      });
    }
  }

  String? _cidadeCache;
  LatLng? _cidadeCentro;

  /// Nome da cidade do ponto (para a busca não sair da região).
  Future<String?> _cidadeDe(LatLng centro) async {
    if (_cidadeCentro == centro) return _cidadeCache;

    _cidadeCentro = centro;
    _cidadeCache = null;

    try {
      final pm = await placemarkFromCoordinates(
        centro.latitude,
        centro.longitude,
      );

      if (pm.isNotEmpty) {
        final c = (pm.first.subAdministrativeArea ?? '').trim();
        final l = (pm.first.locality ?? '').trim();

        _cidadeCache = l.isNotEmpty ? l : (c.isNotEmpty ? c : null);
      }
    } catch (_) {
      // sem cidade: a busca segue só com a região (viewbox)
    }

    return _cidadeCache;
  }

  void _limparBusca() {
    _debounce?.cancel();
    _buscaController.clear();

    setState(() {
      _sugestoes = [];
      _buscando = false;
      _consultaFeita = false;
      _erroBusca = false;
    });
  }

  // ------------------------------------------------------------
  // MAPA
  // ------------------------------------------------------------

  void _irParaMapa(LatLng pos, String endereco) {
    FocusScope.of(context).unfocus();

    setState(() {
      _modoMapa = true;
      _pin = pos;
      _enderecoPin = endereco;
      _resolvendoPin = endereco.isEmpty;
    });

    if (endereco.isEmpty) {
      _resolverEndereco(pos);
    }
  }

  Future<void> _resolverEndereco(LatLng pos) async {
    setState(() {
      _resolvendoPin = true;
      _enderecoPin = '';
    });

    String endereco = '';

    try {
      final pm = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (pm.isNotEmpty) {
        endereco = _enderecoDoPlacemark(pm.first);
      }
    } catch (_) {
      // sem endereço: tratado abaixo
    }

    if (!mounted || _pin != pos) return;

    setState(() {
      _enderecoPin =
          endereco.isNotEmpty ? endereco : 'Endereço não encontrado';
      _resolvendoPin = false;
    });
  }

  void _onMapTap(LatLng pos) {
    setState(() => _pin = pos);

    _resolverEndereco(pos);
  }

  // ------------------------------------------------------------
  // AÇÕES
  // ------------------------------------------------------------

  Future<void> _confirmar(String endereco, LatLng pos) async {
    if (!widget.modoCadastro) {
      await EnderecosStore.registrarRecente(
        endereco,
        pos.latitude,
        pos.longitude,
      );
    }

    if (!mounted) return;

    Navigator.of(context).pop({
      'endereco': endereco,
      'lat': pos.latitude,
      'lng': pos.longitude,
    });
  }

  Future<void> _salvarPin() async {
    final salvo = await mostrarSalvarEndereco(
      context,
      endereco: _enderecoPin,
      lat: _pin.latitude,
      lng: _pin.longitude,
    );

    if (salvo == null) return;

    await EnderecosStore.salvar(salvo);
    await _carregarListas();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${salvo.apelido}" salvo nos seus endereços.')),
    );
  }

  Future<void> _limparRecentes() async {
    await EnderecosStore.limparRecentes();
    await _carregarListas();
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_modoMapa,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _modoMapa) {
          setState(() => _modoMapa = false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopo(),
              Expanded(
                child: _modoMapa ? _buildMapa() : _buildBusca(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_modoMapa) {
                setState(() => _modoMapa = false);
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: Icon(
              _modoMapa
                  ? Icons.arrow_back_rounded
                  : Icons.close_rounded,
              color: pretoPrincipal,
            ),
          ),
          Expanded(
            child: Text(
              widget.titulo,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: pretoPrincipal,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- BUSCA + LISTAS ----------------

  Widget _buildBusca() {
    final consultando = _buscaController.text.trim().length >= 3;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: TextField(
            controller: _buscaController,
            onChanged: _onBuscaChanged,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: pretoPrincipal,
            ),
            decoration: InputDecoration(
              hintText: 'Rua, número, bairro ou cidade',
              hintStyle: const TextStyle(color: cinzaTexto),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: azulPrincipal),
              suffixIcon: _buscando
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: azulPrincipal,
                        ),
                      ),
                    )
                  : (_buscaController.text.isNotEmpty
                      ? IconButton(
                          onPressed: _limparBusca,
                          icon: const Icon(Icons.close_rounded,
                              color: cinzaTexto),
                        )
                      : null),
              filled: true,
              fillColor: cinzaFundo,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: azulPrincipal, width: 1.5),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 24),
            children:
                consultando ? _itensDaBusca() : _itensPadrao(),
          ),
        ),
      ],
    );
  }

  List<Widget> _itensDaBusca() {
    if (_sugestoes.isEmpty) {
      if (_buscando || !_consultaFeita) {
        return [
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Buscando endereços...',
                style: TextStyle(color: cinzaTexto),
              ),
            ),
          ),
        ];
      }

      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 40, 32, 16),
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 44, color: cinzaTexto),
              const SizedBox(height: 12),
              Text(
                _erroBusca
                    ? 'Não foi possível buscar agora'
                    : 'Nenhum endereço encontrado',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: pretoPrincipal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _erroBusca
                    ? 'Verifique sua conexão e tente de novo, ou escolha o ponto no mapa.'
                    : 'Confira o nome da rua ou inclua a cidade (ex.: Rua Antônio Rocha, São Roque).',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: cinzaTexto),
              ),
            ],
          ),
        ),
        _tile(
          icone: Icons.map_outlined,
          titulo: 'Escolher no mapa',
          subtitulo: 'Marque o ponto exato tocando no mapa',
          aoTocar: () => _irParaMapa(_pin, ''),
        ),
      ];
    }

    return [
      for (final s in _sugestoes)
        _tile(
          icone: Icons.place_outlined,
          titulo: s.titulo,
          subtitulo: s.subtitulo,
          aoTocar: () => _irParaMapa(s.pos, s.endereco),
        ),
    ];
  }

  List<Widget> _itensPadrao() {
    return [
      if (_temLocalizacaoAtual)
        _tile(
          icone: Icons.my_location_rounded,
          destaque: true,
          titulo: 'Usar minha localização atual',
          subtitulo: widget.enderecoAtual,
          aoTocar: () => widget.modoCadastro
              ? _irParaMapa(widget.coordenadaAtual!, widget.enderecoAtual)
              : _confirmar(
                  widget.enderecoAtual,
                  widget.coordenadaAtual!,
                ),
        ),
      _tile(
        icone: Icons.map_outlined,
        titulo: 'Escolher no mapa',
        subtitulo: 'Marque o ponto exato tocando no mapa',
        aoTocar: () => _irParaMapa(
          _pin,
          _temLocalizacaoAtual && _pin == widget.coordenadaAtual
              ? widget.enderecoAtual
              : '',
        ),
      ),
      if (!widget.modoCadastro) ...[
        _cabecalhoSecao('ENDEREÇOS SALVOS'),
        if (_salvos.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Você ainda não salvou nenhum endereço. Escolha um ponto '
              'no mapa e toque em "Salvar" para guardar aqui.',
              style: TextStyle(fontSize: 13, color: cinzaTexto),
            ),
          )
        else
          for (final s in _salvos)
            _tile(
              icone: iconeDoTipo(s.tipo),
              titulo: s.apelido,
              subtitulo: s.endereco,
              aoTocar: () =>
                  _confirmar(s.endereco, LatLng(s.lat, s.lng)),
            ),
        if (_recentes.isNotEmpty) ...[
          _cabecalhoSecao(
            'RECENTES',
            acao: 'Limpar',
            aoTocarAcao: _limparRecentes,
          ),
          for (final r in _recentes)
            _tile(
              icone: Icons.history_rounded,
              titulo: r.endereco,
              aoTocar: () =>
                  _confirmar(r.endereco, LatLng(r.lat, r.lng)),
            ),
        ],
      ],
    ];
  }

  Widget _cabecalhoSecao(
    String titulo, {
    String? acao,
    VoidCallback? aoTocarAcao,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cinzaTexto,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (acao != null)
            TextButton(
              onPressed: aoTocarAcao,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 28),
              ),
              child: Text(
                acao,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: azulPrincipal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icone,
    required String titulo,
    String? subtitulo,
    required VoidCallback aoTocar,
    bool destaque = false,
  }) {
    return InkWell(
      onTap: aoTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: destaque
                    ? azulPrincipal
                    : azulPrincipal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icone,
                size: 21,
                color: destaque ? Colors.white : azulPrincipal,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: pretoPrincipal,
                    ),
                  ),
                  if (subtitulo != null && subtitulo.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: cinzaTexto,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- MAPA ----------------

  Widget _buildMapa() {
    final pronto = !_resolvendoPin &&
        _enderecoPin.isNotEmpty &&
        _enderecoPin != 'Endereço não encontrado';

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _pin, zoom: 16),
          markers: {
            Marker(
              markerId: const MarkerId('pin'),
              position: _pin,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ),
          },
          onTap: _onMapTap,
          onMapCreated: (c) => _mapController = c,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PONTO SELECIONADO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: azulPrincipal,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: azulPrincipal, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _resolvendoPin
                          ? const Text(
                              'Buscando endereço...',
                              style: TextStyle(
                                fontSize: 15,
                                color: cinzaTexto,
                              ),
                            )
                          : Text(
                              _enderecoPin.isEmpty
                                  ? 'Toque no mapa para marcar o ponto'
                                  : _enderecoPin,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: pretoPrincipal,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: pronto ? _salvarPin : null,
                        icon: const Icon(Icons.bookmark_border_rounded),
                        label: const Text('Salvar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: azulPrincipal,
                          side: BorderSide(
                            color: pronto
                                ? azulPrincipal
                                : const Color(0xFFDDDDDD),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: pronto
                              ? () => _confirmar(_enderecoPin, _pin)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pretoPrincipal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            widget.textoConfirmar,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
