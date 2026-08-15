import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class Pneu extends StatefulWidget {
  const Pneu({super.key});

  @override
  State<Pneu> createState() => _PneuState();
}

class _PneuState extends State<Pneu> {
  GoogleMapController? _mapController;
  bool _temPermissao = false;

  // Posição inicial (caso ainda não tenha a localização do usuário)
  static const CameraPosition _posicaoInicial = CameraPosition(
    target: LatLng(37.5629, -122.3255),
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _verificarPermissaoEBuscarLocalizacao();
  }

  // Função da Permissão da localização
  Future<void> _verificarPermissaoEBuscarLocalizacao() async {
    bool servicoAtivado;
    LocationPermission permissao;

    // Verifica se o GPS do celular está ligado
    servicoAtivado = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivado) {
      return; // GPS desativado
    }

    // Verifica e pede a permissão
    permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        return; // Permissão negada pelo usuário
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      return; // Permissão negada permanentemente
    }

    // Se tiver Permissão
    setState(() {
      _temPermissao = true;
    });

    _focarNaMinhaLocalizacao();
  }

  Future<void> _focarNaMinhaLocalizacao() async {
    if (_mapController == null) return;

    try {
      Position posicao = await Geolocator.getCurrentPosition();
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(posicao.latitude, posicao.longitude),
            zoom: 16.0,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Erro ao obter localização: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // MAPA AO FUNDO
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _posicaoInicial,
            zoomControlsEnabled: false,
            myLocationEnabled: _temPermissao, 
            myLocationButtonEnabled: false, 
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            // Cria um "padding" no mapa para que a logo do Google 
            // não fique escondida atrás do card movível
            padding: const EdgeInsets.only(bottom: 350), 
          ),

          // BOTÃO VOLTAR
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
            ),
          ),

          // BOTÃO DE ZOOM NA LOCALIZAÇÃO (Lado Direito)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: InkWell(
              onTap: _focarNaMinhaLocalizacao,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.my_location, color: Color(0xFF2563EB)), // Azul
              ),
            ),
          ),

          // CARD MOVÍVEL (DraggableScrollableSheet)
          DraggableScrollableSheet(
            initialChildSize: 0.40, // Começa ocupando 40% da tela
            minChildSize: 0.25,    // Tamanho mínimo ao arrastar pra baixo
            maxChildSize: 0.45,    // Tamanho máximo ao arrastar pra cima
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
                  ],
                ),
                // SingleChildScrollView permite que o card seja arrastado
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pequena "Pílula" indicando que é arrastável
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      
                      const Text(
                        'Procurando o motorista mais\npróximo...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Barra de Progresso
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          value: 0.65,
                          backgroundColor: Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),

                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Buscando em um raio de 5km',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '65%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Card Escuro do Serviço
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2532),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.tire_repair,
                                color: Colors.black87,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pneu Furado (Com\nEstepe)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      height: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Socorro mecânico',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'R\$',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '50,00',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'ESTIMADO',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botão de Cancelar
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B1014),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Cancelar solicitação',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}