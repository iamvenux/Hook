import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'overlay_endereco.dart';
import 'adicionar_veiculo_screen.dart';
import 'solicitar_servico_screen.dart';
import 'perfil_cliente_screen.dart';
import 'api_service.dart';
import 'veiculos_screen.dart';
import 'historico_cliente_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  static const Color azulPrincipal =
      Color(0xFF1A7EF5);

  static const Color pretoPrincipal =
      Color(0xFF1A1A1A);

  static const Color cinzaTexto =
      Color(0xFF8A8A8A);

  static const Color cinzaFundo =
      Color(0xFFF5F5F5);

  int _navSelecionado = 0;

  int _veiculosRefresh = 0;
  int _historicoRefresh = 0;

  int _tipoReboque = 0;

  int _veiculoSelecionado = 0;

  String _enderecoAtual =
      'Obtendo sua localização...';

  LatLng? _coordenadaAtual;

  bool _carregandoLocalizacao = true;

  bool _carregandoVeiculos = true;

  bool _erroVeiculos = false;

  List<Map<String, dynamic>>
      _veiculos = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _carregarVeiculos();
    _carregarLocalizacaoAtual();
  }

  // ============================================================
  // LOCALIZAÇÃO ATUAL DO CLIENTE
  // ============================================================

  Future<void> _carregarLocalizacaoAtual() async {
    try {
      final servicoAtivo =
          await Geolocator.isLocationServiceEnabled();

      if (!servicoAtivo) {
        if (!mounted) return;

        setState(() {
          _enderecoAtual =
              'Ative a localização do dispositivo';
          _carregandoLocalizacao = false;
        });

        return;
      }

      var permissao =
          await Geolocator.checkPermission();

      if (permissao ==
          LocationPermission.denied) {
        permissao =
            await Geolocator.requestPermission();
      }

      if (permissao ==
              LocationPermission.denied ||
          permissao ==
              LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _enderecoAtual =
              'Permissão de localização necessária';
          _carregandoLocalizacao = false;
        });

        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        ),
      );

      final coordenada = LatLng(
        position.latitude,
        position.longitude,
      );

      String endereco =
          'Localização atual';

      try {
        final placemarks =
            await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p =
              placemarks.first;

        final rua =
            p.thoroughfare?.trim() ?? '';

        final numero =
            p.subThoroughfare?.trim() ?? '';

        final bairro =
            p.subLocality?.trim() ?? '';

        final cidade =
            p.locality?.trim() ?? '';

        final estado =
            p.administrativeArea?.trim() ?? '';

        final cep =
            p.postalCode?.trim() ?? '';

        final partes = <String>[];

        if (rua.isNotEmpty) {
          if (numero.isNotEmpty) {
            partes.add('$rua, $numero');
          } else {
            partes.add(rua);
          }
        }

        if (bairro.isNotEmpty) {
          partes.add(bairro);
        }

        if (cidade.isNotEmpty) {
          if (estado.isNotEmpty) {
            partes.add('$cidade - $estado');
          } else {
            partes.add(cidade);
          }
        }

        if (cep.isNotEmpty) {
          partes.add('CEP $cep');
        }

        if (partes.isNotEmpty) {
          endereco = partes.join(', ');
        }

          if (partes.isNotEmpty) {
            endereco =
                partes.join(', ');
          }
        }
      } catch (_) {
        // Mantém "Localização atual" se
        // o endereço não puder ser convertido.
      }

      if (!mounted) return;

      setState(() {
        _coordenadaAtual =
            coordenada;
        _enderecoAtual =
            endereco;
        _carregandoLocalizacao =
            false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _enderecoAtual =
            'Não foi possível obter sua localização';
        _carregandoLocalizacao =
            false;
      });
    }
  }

  // ============================================================
  // CARREGAR VEÍCULOS DO BANCO
  // ============================================================

  Future<void> _carregarVeiculos() async {
    if (mounted) {
      setState(() {
        _carregandoVeiculos = true;
        _erroVeiculos = false;
      });
    }

    try {
      final lista = await ApiService.instance.listarVeiculos();

      if (!mounted) return;

      int selecionado = 0;

      final indicePadrao = lista.indexWhere(
        (v) => v['padrao'].toString() == '1',
      );

      if (indicePadrao >= 0) {
        selecionado = indicePadrao;
      } else if (_veiculoSelecionado < lista.length) {
        selecionado = _veiculoSelecionado;
      }

      setState(() {
        _veiculos = lista;
        _veiculoSelecionado = lista.isEmpty ? 0 : selecionado;
        _carregandoVeiculos = false;
        _erroVeiculos = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _carregandoVeiculos = false;
        _erroVeiculos = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.mensagem),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregandoVeiculos = false;
        _erroVeiculos = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível carregar os veículos.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // ABRIR TELA PARA ADICIONAR
  // ============================================================

  Future<void> _abrirAdicionarVeiculo() async {
    final resultado =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AdicionarVeiculoScreen(),
      ),
    );

    if (!mounted) return;

    // A tela retorna true quando
    // o veículo é salvo com sucesso.
    if (resultado == true) {
      await _carregarVeiculos();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _navSelecionado,
        children: [
          _buildInicio(),

          VeiculosScreen(
            key: ValueKey(_veiculosRefresh),
          ),

          HistoricoClienteScreen(
            key: ValueKey(_historicoRefresh),
          ),

          const PerfilClienteScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildInicio() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              32,
              24,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seja Bem-vindo(a)',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: pretoPrincipal,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Como posso te ajudar hoje ?',
                  style: TextStyle(
                    fontSize: 14,
                    color: cinzaTexto,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(
                  color: Color(0xFFEEEEEE),
                  thickness: 1,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: _buildConteudoResgate(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTEÚDO PRINCIPAL
  // ============================================================

  Widget _buildConteudoResgate() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // ======================================================
        // LOCALIZAÇÃO
        // ======================================================

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration:
              BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color:
                  azulPrincipal,
              width:
                  1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(
                  color:
                      azulPrincipal
                          .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .location_on_rounded,
                  color:
                      azulPrincipal,
                  size: 22,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PONTO DE ENCONTRO',
                      style:
                          TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight
                                .w700,
                        color:
                            cinzaTexto,
                        letterSpacing:
                            0.8,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      _enderecoAtual,
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight
                                .w600,
                        color:
                            azulPrincipal,
                      ),
                    ),
                  ],
                ),
              ),

              if (_carregandoLocalizacao)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: azulPrincipal,
                  ),
                )
              else
                GestureDetector(
                onTap: () async {
                  final resultado =
                      await showGeneralDialog<
                          dynamic>(
                    context:
                        context,
                    barrierDismissible:
                        false,
                    barrierColor:
                        Colors.transparent,
                    transitionDuration:
                        Duration.zero,
                    pageBuilder:
                        (_, _, _) =>
                            EnderecoOverlay(
                      enderecoAtual:
                          _enderecoAtual,
                      coordenadaAtual:
                          _coordenadaAtual,
                    ),
                  );

                  if (resultado !=
                          null &&
                      mounted) {
                    final r =
                        resultado
                            as Map<
                                String,
                                dynamic>;

                    setState(() {
                      _enderecoAtual =
                          r['endereco']
                              as String;

                      _coordenadaAtual =
                          LatLng(
                        (r['lat']
                                as num)
                            .toDouble(),
                        (r['lng']
                                as num)
                            .toDouble(),
                      );
                    });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        pretoPrincipal,
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),
                  child:
                      const Text(
                    'Mudar',
                    style:
                        TextStyle(
                      color:
                          Colors.white,
                      fontSize: 13,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 24,
        ),

        // ======================================================
        // CABEÇALHO VEÍCULOS
        // ======================================================

        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
          children: [
            const Text(
              'SEU VEÍCULO',
              style:
                  TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
                color:
                    cinzaTexto,
                letterSpacing:
                    1.2,
              ),
            ),

            GestureDetector(
              onTap:
                  _abrirAdicionarVeiculo,
              child:
                  const Text(
                '+ ADICIONAR NOVO',
                style:
                    TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight
                          .w700,
                  color:
                      azulPrincipal,
                  letterSpacing:
                      0.8,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // VEÍCULOS
        // ======================================================

        _buildVeiculos(),

        const SizedBox(
          height: 24,
        ),

        // ======================================================
        // TIPO DE REBOQUE
        // ======================================================

        const Text(
          'TIPO DE REBOQUE',
          style:
              TextStyle(
            fontSize: 11,
            fontWeight:
                FontWeight.w700,
            color:
                cinzaTexto,
            letterSpacing:
                1.2,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Row(
          children: [
            Expanded(
              child:
                  _buildTipoReboque(
                0,
                Icons
                    .local_shipping_rounded,
                'Guincho Leve',
                'Até 3.5 toneladas',
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child:
                  _buildTipoReboque(
                1,
                Icons
                    .rv_hookup_rounded,
                'Guincho Pesado',
                'Caminhões e ônibus',
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 28,
        ),

        // ======================================================
        // SOLICITAR RESGATE
        // ======================================================

        SizedBox(
          width:
              double.infinity,
          height: 56,
          child:
              ElevatedButton(
            onPressed:
                _veiculos.isEmpty
                    ? null
                    : _solicitarResgate,

            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  pretoPrincipal,

              foregroundColor:
                  Colors.white,

              disabledBackgroundColor:
                  Colors.grey
                      .shade400,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  28,
                ),
              ),

              elevation: 0,
            ),

            child:
                const Text(
              'Solicitar Resgate',
              style:
                  TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w600,
                letterSpacing:
                    0.3,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 24,
        ),
      ],
    );
  }

  // ============================================================
  // LISTA DE VEÍCULOS
  // ============================================================

  Widget _buildVeiculos() {
  if (_carregandoVeiculos) {
    return const SizedBox(
      height: 170,
      child: Center(
        child: CircularProgressIndicator(
          color: azulPrincipal,
        ),
      ),
    );
  }

  if (_erroVeiculos) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
          ),
          const SizedBox(height: 8),
          const Text(
            'Não foi possível carregar os veículos.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _carregarVeiculos,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  if (_veiculos.isEmpty) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 26,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: cinzaFundo,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.directions_car_outlined,
            size: 34,
            color: cinzaTexto,
          ),
          const SizedBox(height: 10),
          const Text(
            'Nenhum veículo cadastrado',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: pretoPrincipal,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cadastre um veículo para solicitar um resgate.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: cinzaTexto,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _abrirAdicionarVeiculo,
            child: const Text('Adicionar veículo'),
          ),
        ],
      ),
    );
  }

  return SizedBox(
    height: 170,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _veiculos.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final v = _veiculos[index];

        final selecionado =
            _veiculoSelecionado == index;

        final padrao =
            v['padrao'].toString() == '1';

        final nome =
            '${v['marca'] ?? ''} ${v['modelo'] ?? ''}'.trim();

        final placa =
            v['placa']?.toString() ?? '';

        final cor =
            v['cor']?.toString() ?? '';

        final ano =
            v['ano']?.toString() ?? '';

        return GestureDetector(
          onTap: () {
            setState(() {
              _veiculoSelecionado = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),

            // Largura de cada card
            width: 180,

            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(
              color: selecionado
                  ? pretoPrincipal
                  : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(16),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: selecionado
                            ? Colors.white.withValues(
                                alpha: 0.15,
                              )
                            : Colors.white,
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _iconeVeiculo(
                          v['tipo']?.toString(),
                        ),
                        color: selecionado
                            ? Colors.white
                            : pretoPrincipal,
                        size: 20,
                      ),
                    ),

                    if (padrao)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: azulPrincipal,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'PADRÃO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                  ],
                ),

                const Spacer(),

                Text(
                  nome.isEmpty ? 'Veículo' : nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: selecionado
                        ? Colors.white
                        : pretoPrincipal,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  placa,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: selecionado
                        ? Colors.white.withValues(
                            alpha: 0.6,
                          )
                        : cinzaTexto,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 7,
                      color: selecionado
                          ? Colors.white.withValues(
                              alpha: 0.5,
                            )
                          : cinzaTexto,
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        '$cor • $ano',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: selecionado
                              ? Colors.white.withValues(
                                  alpha: 0.6,
                                )
                              : cinzaTexto,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  // ============================================================
  // SOLICITAR
  // ============================================================

  void _solicitarResgate() {
    if (_veiculos.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastre um veículo primeiro.',
          ),
        ),
      );

      return;
    }

    final coordenada =
        _coordenadaAtual;

    if (coordenada == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Aguarde a localização atual ou selecione um ponto de encontro.',
          ),
        ),
      );

      return;
    }

    const tiposReboque = [
      'Guincho Leve',
      'Guincho Pesado',
    ];

    final veiculo =
        _veiculos[
            _veiculoSelecionado];

    final veiculoId =
        _paraInt(
      veiculo['id'],
    );

    if (veiculoId ==
        null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Veículo inválido.',
          ),
        ),
      );

      return;
    }

    final marca =
        veiculo['marca']
                ?.toString() ??
            '';

    final modelo =
        veiculo['modelo']
                ?.toString() ??
            '';

    final nomeVeiculo =
        '$marca $modelo'
            .trim();

    final servico =
        tiposDeReboque[
            tiposReboque[
                _tipoReboque]];

    if (servico == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Tipo de reboque inválido.',
          ),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ResumoServicoScreen(
          servico:
              servico,
          endereco:
              _enderecoAtual,
          coordenada:
              coordenada,
          veiculo:
              nomeVeiculo.isEmpty
                  ? 'Veículo'
                  : nomeVeiculo,
          veiculoId:
              veiculoId,
        ),
      ),
    );
  }

  // ============================================================
  // TIPO REBOQUE
  // ============================================================

  Widget _buildTipoReboque(
    int index,
    IconData icone,
    String titulo,
    String subtitulo,
  ) {
    final selecionado =
        _tipoReboque ==
            index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoReboque =
              index;
        });
      },

      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds:
              200,
        ),

        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 10,
          vertical: 14,
        ),

        decoration:
            BoxDecoration(
          color: selecionado
              ? azulPrincipal
                  .withValues(
                  alpha:
                      0.07,
                )
              : Colors.white,

          borderRadius:
              BorderRadius
                  .circular(
            14,
          ),

          border:
              Border.all(
            color: selecionado
                ? azulPrincipal
                : const Color(
                    0xFFDDDDDD,
                  ),

            width: selecionado
                ? 1.8
                : 1.5,
          ),
        ),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              icone,
              size:
                  30,
              color: selecionado
                  ? azulPrincipal
                  : cinzaTexto,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              titulo,
              maxLines:
                  1,
              overflow:
                  TextOverflow
                      .ellipsis,
              style:
                  TextStyle(
                fontSize:
                    13,
                fontWeight:
                    FontWeight
                        .w700,
                color: selecionado
                    ? pretoPrincipal
                    : cinzaTexto,
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            Text(
              subtitulo,
              maxLines:
                  2,
              overflow:
                  TextOverflow
                      .ellipsis,
              style:
                  const TextStyle(
                fontSize:
                    11,
                color:
                    cinzaTexto,
              ),
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ÍCONE VEÍCULO
  // ============================================================

  IconData _iconeVeiculo(
    String? tipo,
  ) {
    switch (tipo) {
      case 'Moto':
        return Icons
            .two_wheeler_rounded;

      case 'SUV':
        return Icons
            .airport_shuttle_rounded;

      case 'Carro':
      default:
        return Icons
            .directions_car_rounded;
    }
  }

  // ============================================================
  // CONVERTER ID
  // ============================================================

  int? _paraInt(
    dynamic valor,
  ) {
    if (valor == null) {
      return null;
    }

    if (valor is int) {
      return valor;
    }

    return int.tryParse(
      valor.toString(),
    );
  }

  // ============================================================
  // BOTTOM NAV
  // ============================================================

  Widget _buildBottomNav() {
    return SizedBox(
      height: 80,
      child: BottomNavigationBar(
        currentIndex: _navSelecionado,
        onTap: (index) async {
          setState(() {
            _navSelecionado = index;

            if (index == 1) {
              _veiculosRefresh++;
            }

            if (index == 2) {
              _historicoRefresh++;
            }
          });

          if (index == 0) {
            await _carregarVeiculos();
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: pretoPrincipal,
        selectedItemColor: azulPrincipal,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'INÍCIO',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car_rounded),
            label: 'VEÍCULOS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'HISTÓRICO',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'PERFIL',
          ),
        ],
      ),
    );
  }

}