import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_application_1/controllers/solicitacao_controller.dart';
import 'package:flutter_application_1/models/servico_config.dart';
import 'package:flutter_application_1/services/rota_service.dart';

// ─────────────────────────────────────────────
// TELA 2 — PROCURANDO / ACOMPANHANDO MOTORISTA
// ─────────────────────────────────────────────

class ProcurandoProfissionalScreen
    extends StatefulWidget {
  final ServicoConfig servico;
  final String endereco;
  final LatLng coordenada;
  final String veiculo;
  final int solicitacaoId;

  const ProcurandoProfissionalScreen({
    super.key,
    required this.servico,
    required this.endereco,
    required this.coordenada,
    required this.veiculo,
    required this.solicitacaoId,
  });

  @override
  State<ProcurandoProfissionalScreen> createState() =>
      _ProcurandoProfissionalScreenState();
}

class _ProcurandoProfissionalScreenState
    extends State<ProcurandoProfissionalScreen> {
  static const Color azulPrincipal =
      Color(0xFF1A7EF5);

  static const Color pretoPrincipal =
      Color(0xFF1A1A1A);

  static const Color cardEscuro =
      Color(0xFF1C2C3E);

  // ─────────────────────────────────────────────
  // CONFIGURAÇÃO DO ACOMPANHAMENTO
  // ─────────────────────────────────────────────

  // Atualiza a posição aproximadamente a cada 1 segundo.
  static const Duration intervaloAtualizacao =
      Duration(seconds: 1);

  final DraggableScrollableController
      _sheetController =
      DraggableScrollableController();

  final double _tamanhoInicialPainel = 0.42;
  final double _tamanhoAceitePainel = 0.62;

  GoogleMapController? _mapController;

  Timer? _pollingTimer;

  // Impede duas requisições simultâneas.
  bool _consultando = false;

  ServicoConfig get _servico => widget.servico;

  String _status = 'buscando';

  String _mensagem =
      'Procurando o guincho mais próximo...';

  Map<String, dynamic>? _motorista;

  bool _carregando = true;
  bool _erro = false;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Guarda a última posição recebida.
  LatLng? _ultimaPosicaoMotorista;

  @override
  void initState() {
    super.initState();

    _markers.add(
      Marker(
        markerId: const MarkerId('encontro'),
        position: widget.coordenada,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
      ),
    );

    // Consulta imediatamente ao abrir a tela.
    _consultarStatus();

    // Depois continua consultando a cada 1 segundo.
    _pollingTimer = Timer.periodic(
      intervaloAtualizacao,
      (_) {
        _consultarStatus();
      },
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();

    _sheetController.dispose();

    _mapController?.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────────
  // CONSULTAR STATUS
  // ─────────────────────────────────────────────

  Future<void> _consultarStatus() async {
    // Se já existe uma consulta em andamento,
    // não começa outra.
    if (_consultando) {
      return;
    }

    _consultando = true;

    try {
      final resp =
          await SolicitacaoController.instance.consultarSolicitacao(
        widget.solicitacaoId,
      );

      if (!mounted) return;

      final solicitacao =
          resp['solicitacao'] as Map<String, dynamic>;

      final novoStatus =
          solicitacao['status'] as String;

      final motorista =
          resp['motorista'] as Map<String, dynamic>?;

      final novaMensagem =
          (resp['mensagem'] as String?) ??
              _mensagem;

      setState(() {
        _status = novoStatus;

        _mensagem = novaMensagem;

        _motorista = motorista;

        _carregando = false;

        _erro = false;
      });

      // ─────────────────────────────────────────
      // MOTORISTA ENCONTRADO
      // ─────────────────────────────────────────

      if (motorista != null) {
        _abrirPainelMotorista();

        final latitude =
            motorista['latitude'];

        final longitude =
            motorista['longitude'];

        if (latitude != null &&
            longitude != null) {
          final lat = double.tryParse(
            latitude.toString(),
          );

          final lng = double.tryParse(
            longitude.toString(),
          );

          if (lat != null && lng != null) {
            final posMotorista =
                LatLng(lat, lng);

            await _atualizarPosicaoMotorista(
              posMotorista,
            );
          }
        }
      }

      // ─────────────────────────────────────────
      // FINALIZAÇÃO
      // ─────────────────────────────────────────

      if (novoStatus == 'concluido' ||
          novoStatus == 'cancelado') {
        _pollingTimer?.cancel();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = true;
      });
    } finally {
      _consultando = false;
    }
  }

  // ─────────────────────────────────────────────
  // ATUALIZA POSIÇÃO DO MOTORISTA
  // ─────────────────────────────────────────────

  Future<void> _atualizarPosicaoMotorista(
    LatLng novaPosicao,
  ) async {
    if (!mounted) return;

    final posicaoAnterior =
        _ultimaPosicaoMotorista;

    _ultimaPosicaoMotorista =
        novaPosicao;

    setState(() {
      _markers = {
        _markers.firstWhere(
          (marker) =>
              marker.markerId.value ==
              'encontro',
        ),
        Marker(
          markerId:
              const MarkerId('motorista'),
          position: novaPosicao,
          icon: BitmapDescriptor
              .defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title:
                _motorista?['nome'] as String? ??
                    'Motorista',
          ),
        ),
      };
    });

    // Só recalcula a rota se o motorista
    // realmente mudou de posição.
    if (posicaoAnterior == null ||
        _distanciaAproximada(
              posicaoAnterior,
              novaPosicao,
            ) >
            5) {
      await _buscarRota(
        novaPosicao,
        widget.coordenada,
      );
    }
  }

  // Verifica aproximadamente quantos metros
  // o motorista se moveu.
  double _distanciaAproximada(
    LatLng a,
    LatLng b,
  ) {
    const fatorLatitude = 111000.0;

    final diferencaLatitude =
        (a.latitude - b.latitude).abs();

    final diferencaLongitude =
        (a.longitude - b.longitude).abs();

    final metrosLatitude =
        diferencaLatitude * fatorLatitude;

    final metrosLongitude =
        diferencaLongitude *
            fatorLatitude *
            0.85;

    return metrosLatitude +
        metrosLongitude;
  }

  // ─────────────────────────────────────────────
  // ABRIR PAINEL DO MOTORISTA
  // ─────────────────────────────────────────────

  void _abrirPainelMotorista() {
    if (!_sheetController.isAttached) {
      return;
    }

    if (_sheetController.size <
        _tamanhoAceitePainel - 0.02) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (!mounted) return;

        if (!_sheetController.isAttached) {
          return;
        }

        _sheetController.animateTo(
          _tamanhoAceitePainel,
          duration:
              const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // ─────────────────────────────────────────────
  // BUSCAR ROTA
  // ─────────────────────────────────────────────

  Future<void> _buscarRota(
    LatLng origem,
    LatLng destino,
  ) async {
    // Se o serviço de rotas falhar, volta null e
    // o acompanhamento continua funcionando.
    final rota =
        await RotaService.instance.buscarRota(
      origem,
      destino,
    );

    if (rota == null || !mounted) return;

    setState(() {
      _polylines = {
        Polyline(
          polylineId:
              const PolylineId(
            'rota_profissional',
          ),
          points: rota.pontos,
          color: azulPrincipal,
          width: 5,
        ),
      };
    });
  }

  // ─────────────────────────────────────────────
  // CANCELAR
  // ─────────────────────────────────────────────

  Future<void> _cancelar() async {
    _pollingTimer?.cancel();

    try {
      await SolicitacaoController.instance.cancelarSolicitacao(
        widget.solicitacaoId,
      );
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // ─────────────────────────────────────────────
  // INTERFACE
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final alturaTela =
        MediaQuery.of(context).size.height;

    final paddingInferiorMapa =
        alturaTela *
            _tamanhoInicialPainel;

    final temMotorista =
        _motorista != null;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(
              target: widget.coordenada,
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController =
                  controller;
            },
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            padding: EdgeInsets.only(
              bottom:
                  paddingInferiorMapa,
            ),
          ),

          // Botão de voltar no topo esquerdo, abaixo da barra
          // de status, alinhado com o selo do serviço à direita.
          Positioned(
            top:
                MediaQuery.of(context)
                        .padding
                        .top +
                    16,
            left: 16,
            child: FloatingActionButton.small(
              heroTag:
                  'btn_back_servico',
              backgroundColor:
                  Colors.white,
              elevation: 2,
              onPressed: () =>
                  Navigator.of(context)
                      .pop(),
              child: const Icon(
                Icons.arrow_back,
                color:
                    pretoPrincipal,
              ),
            ),
          ),

          Positioned(
            top:
                MediaQuery.of(context)
                        .padding
                        .top +
                    16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(
                      0.12,
                    ),
                    blurRadius: 8,
                    offset:
                        const Offset(
                      0,
                      2,
                    ),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    _servico.icone,
                    color:
                        azulPrincipal,
                    size: 16,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Text(
                    _servico.titulo,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          pretoPrincipal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          DraggableScrollableSheet(
            controller:
                _sheetController,
            initialChildSize:
                _tamanhoInicialPainel,
            minChildSize: 0.15,
            maxChildSize:
                _tamanhoAceitePainel,
            builder:
                (
              context,
              scrollController,
            ) {
              return Container(
                decoration:
                    const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(
                    top:
                        Radius.circular(
                      24,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ListView(
                  controller:
                      scrollController,
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    20,
                    16,
                    20,
                    0,
                  ),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin:
                            const EdgeInsets
                                .only(
                          bottom: 18,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.grey[300],
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                      ),
                    ),

                    if (_erro)
                      const Text(
                        'Não foi possível consultar o status agora. Tentando novamente...',
                        style:
                            TextStyle(
                          fontSize: 14,
                          color:
                              Colors.red,
                        ),
                      )
                    else
                      Text(
                        _mensagem,
                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              pretoPrincipal,
                        ),
                      ),

                    const SizedBox(
                      height: 16,
                    ),

                    if (!temMotorista) ...[
                      const ClipRRect(
                        borderRadius:
                            BorderRadius.all(
                          Radius.circular(
                            8,
                          ),
                        ),
                        child:
                            LinearProgressIndicator(
                          minHeight: 9,
                          backgroundColor:
                              Color(
                            0xFFE0E0E0,
                          ),
                          valueColor:
                              AlwaysStoppedAnimation<
                                  Color>(
                            azulPrincipal,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .all(
                          14,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFF5F5F5,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .location_on_rounded,
                              color:
                                  pretoPrincipal,
                              size: 16,
                            ),
                            const SizedBox(
                              width: 6,
                            ),
                            Expanded(
                              child: Text(
                                widget
                                    .endereco,
                                style:
                                    const TextStyle(
                                  fontSize:
                                      12,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                  color:
                                      pretoPrincipal,
                                ),
                                maxLines: 2,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (temMotorista) ...[
                      Container(
                        padding:
                            const EdgeInsets
                                .all(
                          16,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              cardEscuro,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration:
                                  BoxDecoration(
                                shape:
                                    BoxShape
                                        .circle,
                                border:
                                    Border.all(
                                  color:
                                      Colors
                                          .white24,
                                  width: 2,
                                ),
                                color:
                                    Colors
                                        .white24,
                              ),
                              child:
                                  const Icon(
                                Icons.person,
                                color:
                                    Colors
                                        .white54,
                                size: 28,
                              ),
                            ),

                            const SizedBox(
                              width: 16,
                            ),

                            Expanded(
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    _motorista![
                                            'nome']
                                        as String? ??
                                        'Motorista',
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          18,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color:
                                          Colors
                                              .white,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 6,
                                  ),

                                  if (_motorista![
                                          'placa'] !=
                                      null)
                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal:
                                            8,
                                        vertical:
                                            4,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            const Color
                                                .fromARGB(
                                          164,
                                          36,
                                          94,
                                          145,
                                        ),
                                        border:
                                            Border.all(
                                          color:
                                              const Color
                                                  .fromARGB(
                                            255,
                                            36,
                                            94,
                                            145,
                                          ),
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          20,
                                        ),
                                      ),
                                      child:
                                          Text(
                                        _motorista![
                                                'placa']
                                            as String,
                                        style:
                                            const TextStyle(
                                          fontSize:
                                              12,
                                          color:
                                              Colors
                                                  .white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            Text(
                              _servico
                                  .valorEstimado,
                              style:
                                  const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight
                                        .w800,
                                color:
                                    Colors
                                        .white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      if (_motorista![
                              'telefone'] !=
                          null)
                        SizedBox(
                          width:
                              double.infinity,
                          child:
                              ElevatedButton
                                  .icon(
                            icon:
                                const Icon(
                              Icons
                                  .phone_outlined,
                              size: 18,
                            ),
                            label: Text(
                              'Ligar para ${_motorista!['telefone']}',
                            ),
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF0C44AC,
                              ),
                              foregroundColor:
                                  Colors
                                      .white,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 14,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  24,
                                ),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {},
                          ),
                        ),

                      const SizedBox(
                        height: 12,
                      ),
                    ],

                    const SizedBox(
                      height: 8,
                    ),

                    if (_status !=
                            'concluido' &&
                        _status !=
                            'cancelado')
                      SizedBox(
                        width:
                            double.infinity,
                        height: 54,
                        child:
                            OutlinedButton(
                          onPressed:
                              _cancelar,
                          style:
                              OutlinedButton
                                  .styleFrom(
                            foregroundColor:
                                pretoPrincipal,
                            side:
                                const BorderSide(
                              color:
                                  Color(
                                0xFFDDDDDD,
                              ),
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                28,
                              ),
                            ),
                          ),
                          child:
                              const Text(
                            'Cancelar solicitação',
                            style:
                                TextStyle(
                              fontSize:
                                  15,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      ),

                    if (_status ==
                        'concluido')
                      Container(
                        padding:
                            const EdgeInsets
                                .all(
                          16,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .green
                              .withOpacity(
                            0.08,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons
                                  .check_circle_rounded,
                              color:
                                  Colors.green,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Text(
                                'Serviço concluído! Obrigado por usar o Hook.',
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(
                      height: 24,
                    ),
                  ],
                ),
              );
            },
          ),

          if (_carregando)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(
                  child:
                      CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}