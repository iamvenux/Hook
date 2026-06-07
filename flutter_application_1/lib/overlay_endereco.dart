import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

const Color azulPrincipal = Color(0xFF1A7EF5);
const Color pretoPrincipal = Color(0xFF1A1A1A);
const Color cinzaTexto = Color(0xFF8A8A8A);
const Color cinzaFundo = Color(0xFFF5F5F5);

class EnderecoOverlay extends StatefulWidget {
  final String enderecoAtual;
  final LatLng? coordenadaAtual;

  const EnderecoOverlay({
    super.key,
    required this.enderecoAtual,
    this.coordenadaAtual,
  });

  @override
  State<EnderecoOverlay> createState() => _EnderecoOverlayState();
}

class _EnderecoOverlayState extends State<EnderecoOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  LatLng _destinoSelecionado = const LatLng(-23.5650, -46.6520);
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  late String _pontoEncontro;
  late TextEditingController _pontoController;
  bool _editando = false;
  int _atalhoSelecionado = 0;
  Timer? _debounce;
  bool _buscandoEndereco = false;

  final List<Map<String, dynamic>> _atalhos = [
    {'icone': Icons.home_rounded, 'label': 'Casa'},
    {'icone': Icons.work_rounded, 'label': 'Trabalho'},
    {'icone': Icons.build_rounded, 'label': 'Oficina'},
    {'icone': Icons.favorite_rounded, 'label': 'Favorito'},
    {'icone': Icons.star_rounded, 'label': 'Salvo'},
  ];

  @override
  void initState() {
    super.initState();

    _pontoEncontro = widget.enderecoAtual;
    _pontoController = TextEditingController(text: widget.enderecoAtual);

    // Usa a coordenada salva anteriormente se existir
    if (widget.coordenadaAtual != null) {
      _destinoSelecionado = widget.coordenadaAtual!;
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();

    _markers.add(Marker(
      markerId: const MarkerId('destino'),
      position: _destinoSelecionado,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));
  }
  @override
  void dispose() {
    _debounce?.cancel();
    _animController.dispose();
    _mapController?.dispose();
    _pontoController.dispose();
    super.dispose();
  }

  void _onEnderecoDigitado(String texto) {
    _debounce?.cancel();
    if (texto.trim().length < 5) return;

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _buscandoEndereco = true);

      try {
        final locations = await locationFromAddress(texto);
        if (locations.isNotEmpty && mounted) {
          final loc = locations.first;
          final novaPos = LatLng(loc.latitude, loc.longitude);

          setState(() {
            _destinoSelecionado = novaPos;
            _pontoEncontro = texto;
            _markers
              ..clear()
              ..add(Marker(
                markerId: const MarkerId('destino'),
                position: novaPos,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
              ));
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(novaPos, 15),
          );
        }
      } catch (_) {
        // endereço não encontrado, mapa permanece no lugar
      } finally {
        if (mounted) setState(() => _buscandoEndereco = false);
      }
    });
  }

  void _onMapTap(LatLng posicao) async {
    setState(() {
      _destinoSelecionado = posicao;
      _pontoEncontro = 'Buscando endereço...';
      _pontoController.text = 'Buscando endereço...';
      _editando = false;
      _markers
        ..clear()
        ..add(Marker(
          markerId: const MarkerId('destino'),
          position: posicao,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        posicao.latitude,
        posicao.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final endereco = [
          if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty) p.thoroughfare,
          if (p.subThoroughfare != null && p.subThoroughfare!.isNotEmpty) p.subThoroughfare,
          if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality,
        ].join(', ');

        setState(() {
          _pontoEncontro = endereco.isNotEmpty ? endereco : 'Endereço não encontrado';
          _pontoController.text = _pontoEncontro;
        });
      }
    } catch (e) {
      setState(() {
        _pontoEncontro = 'Endereço não encontrado';
        _pontoController.text = _pontoEncontro;
      });
    }
  }

  void _fechar() {
    _animController.reverse().then((_) => Navigator.of(context).pop());
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnim,
            child: GestureDetector(
              onTap: _fechar,
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ONDE PODEMOS TE AJUDAR?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: pretoPrincipal,
                                letterSpacing: 0.5,
                              ),
                            ),
                            GestureDetector(
                              onTap: _fechar,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: cinzaFundo,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 18, color: pretoPrincipal),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Ponto de Encontro editável
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: cinzaFundo,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _editando ? azulPrincipal : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: azulPrincipal, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PONTO DE ENCONTRO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: azulPrincipal,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    _editando
                                        ? TextField(
                                            controller: _pontoController,
                                            autofocus: true,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: pretoPrincipal,
                                            ),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                              border: InputBorder.none,
                                            ),
                                            onChanged: _onEnderecoDigitado,
                                            onSubmitted: (valor) {
                                              setState(() {
                                                _pontoEncontro = valor;
                                                _editando = false;
                                              });
                                            },
                                          )
                                        : GestureDetector(
                                            onTap: () => setState(() => _editando = true),
                                            child: Text(
                                              _pontoEncontro,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: pretoPrincipal,
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                              if (_buscandoEndereco)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: azulPrincipal,
                                  ),
                                )
                              else if (_editando)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _pontoEncontro = _pontoController.text;
                                      _editando = false;
                                    });
                                  },
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: azulPrincipal,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Locais salvos
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'LOCAIS SALVOS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cinzaTexto,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: List.generate(_atalhos.length, (index) {
                            final item = _atalhos[index];
                            final selecionado = _atalhoSelecionado == index;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _atalhoSelecionado = index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.only(
                                    right: index < _atalhos.length - 1 ? 10 : 0),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selecionado
                                      ? pretoPrincipal
                                      : const Color(0xFF1A3A5C),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(item['icone'] as IconData,
                                        color: Colors.white, size: 18),
                                    AnimatedSize(
                                      duration: const Duration(milliseconds: 220),
                                      curve: Curves.easeInOut,
                                      child: selecionado
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const SizedBox(width: 6),
                                                Text(
                                                  item['label'] as String,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Label mapa
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'SELECIONE NO MAPA O PONTO DE ENCONTRO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cinzaTexto,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Google Maps
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 180,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _destinoSelecionado,
                                zoom: 14,
                              ),
                              markers: _markers,
                              onTap: _onMapTap,
                              onMapCreated: (controller) {
                                _mapController = controller;
                              },
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Botão Confirmar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              final enderecoFinal = _editando
                                  ? _pontoController.text
                                  : _pontoEncontro;
                              Navigator.of(context).pop({
                                'endereco': enderecoFinal,
                                'lat': _destinoSelecionado.latitude,
                                'lng': _destinoSelecionado.longitude,
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: pretoPrincipal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Confirmar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}