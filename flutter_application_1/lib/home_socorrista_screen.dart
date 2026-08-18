import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'api_service.dart';
import 'rota_socorrista_screen.dart';
import 'perfil_socorrista_screen.dart';

// ============================================================
// MODELO DO CHAMADO
// ============================================================

class ChamadoDisponivel {
  final int id;

  final String nomeUsuario;
  final String? telefoneUsuario;

  final String servico;

  final double distanciaKm;

  final String endereco;

  final double latitude;
  final double longitude;

  final double valorEstimado;

  final String formaPagamento;

  final String veiculo;
  final String? placaVeiculo;

  final DateTime criadoEm;

  const ChamadoDisponivel({
    required this.id,
    required this.nomeUsuario,
    this.telefoneUsuario,
    required this.servico,
    required this.distanciaKm,
    required this.endereco,
    required this.latitude,
    required this.longitude,
    required this.valorEstimado,
    required this.formaPagamento,
    required this.veiculo,
    this.placaVeiculo,
    required this.criadoEm,
  });
}

// ============================================================
// HOME SOCORRISTA
// ============================================================

class HomeSocorristaScreen extends StatefulWidget {
  const HomeSocorristaScreen({
    super.key,
  });

  @override
  State<HomeSocorristaScreen> createState() =>
      _HomeSocorristaScreenState();
}

class _HomeSocorristaScreenState
    extends State<HomeSocorristaScreen> {
  static const Color azulPrincipal =
      Color(0xFF1A7EF5);

  static const Color cinzaTexto =
      Color(0xFF8A8A8A);

  static const Color pretoPrincipal =
      Color(0xFF1A1A1A);

  static const Color cinzaFundo =
      Color(0xFFF5F5F5);

  static const Color verdeOnline =
      Color(0xFF22C55E);

  static const Color cinzaOffline =
      Color(0xFFB0B0B0);

  // ============================================================
  // ESTADOS
  // ============================================================

  bool _online = false;

  bool _carregando = false;

  bool _buscandoChamados = false;

  bool _aceitandoChamado = false;

  bool _erroBusca = false;

  int _tabIndex = 0;

  final List<ChamadoDisponivel> _chamados = [];

  Timer? _pollingTimer;

  Position? _posicaoAtual;

  // ============================================================
  // DADOS DO MOTORISTA LOGADO
  // ============================================================

  String get _nomeSocorrista {
    return ApiService.instance.nomeUsuario ??
        'Motorista';
  }

  String get _tipoAtuacao {
    return 'Motorista';
  }

  // ============================================================
  // INIT / DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();

    super.dispose();
  }

  // ============================================================
  // PERMISSÃO DE LOCALIZAÇÃO
  // ============================================================

  Future<bool> _verificarPermissaoLocalizacao() async {
    final servicoAtivo =
        await Geolocator.isLocationServiceEnabled();

    if (!servicoAtivo) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ative a localização do dispositivo.',
          ),
        ),
      );

      return false;
    }

    LocationPermission permissao =
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
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permissão de localização necessária.',
          ),
        ),
      );

      return false;
    }

    return true;
  }

  // ============================================================
  // PEGAR LOCALIZAÇÃO
  // ============================================================

  Future<Position?> _obterLocalizacao() async {
    final permitido =
        await _verificarPermissaoLocalizacao();

    if (!permitido) {
      return null;
    }

    try {
      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
        ),
      );

      _posicaoAtual = position;

      return position;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // ONLINE / OFFLINE
  // ============================================================

  Future<void> _toggleOnline(
    bool valor,
  ) async {
    if (_carregando) return;

    setState(() {
      _carregando = true;
    });

    try {
      if (valor) {
        final position =
            await _obterLocalizacao();

        if (position == null) {
          if (!mounted) return;

          setState(() {
            _carregando = false;
            _online = false;
          });

          return;
        }

        // Salva a posição inicial no banco.
        await ApiService.instance
            .atualizarLocalizacao(
          latitude:
              position.latitude,
          longitude:
              position.longitude,
        );

        // Motorista fica disponível.
        await ApiService.instance
            .atualizarDisponibilidade(
          disponivel: true,
        );

        if (!mounted) return;

        setState(() {
          _online = true;
          _carregando = false;
        });

        await _buscarChamados();

        _iniciarPolling();
      } else {
        _pollingTimer?.cancel();

        await ApiService.instance
            .atualizarDisponibilidade(
          disponivel: false,
        );

        if (!mounted) return;

        setState(() {
          _online = false;
          _carregando = false;
          _chamados.clear();
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.mensagem,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível atualizar sua disponibilidade.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // POLLING DE CHAMADOS
  // ============================================================

  void _iniciarPolling() {
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_online) {
          _buscarChamados(
            mostrarCarregamento: false,
          );
        }
      },
    );
  }

  // ============================================================
  // BUSCAR CHAMADOS REAIS
  // ============================================================

  Future<void> _buscarChamados({
    bool mostrarCarregamento = true,
  }) async {
    if (!_online) return;

    if (_buscandoChamados) return;

    _buscandoChamados = true;

    if (mostrarCarregamento &&
        mounted) {
      setState(() {
        _erroBusca = false;
      });
    }

    try {
      final resultado =
          await ApiService.instance
              .buscarSolicitacoes();

      if (!mounted) return;

      // Atualiza posição do motorista
      // de tempos em tempos.
      final position =
          await _obterLocalizacao();

      if (position != null) {
        try {
          await ApiService.instance
              .atualizarLocalizacao(
            latitude:
                position.latitude,
            longitude:
                position.longitude,
          );
        } catch (_) {
          // Não bloqueia a lista por erro
          // de atualização da localização.
        }
      }

      final lista =
          <ChamadoDisponivel>[];

      for (final item in resultado) {
        final clienteRaw =
            item['cliente'];

        final veiculoRaw =
            item['veiculo'];

        final cliente =
            clienteRaw is Map
                ? Map<String, dynamic>.from(
                    clienteRaw,
                  )
                : <String, dynamic>{};

        final veiculo =
            veiculoRaw is Map
                ? Map<String, dynamic>.from(
                    veiculoRaw,
                  )
                : <String, dynamic>{};

        final latitude =
            _paraDouble(
          item['latitude'],
        );

        final longitude =
            _paraDouble(
          item['longitude'],
        );

        double distanciaKm = 0;

        if (_posicaoAtual != null) {
          final distanciaMetros =
              Geolocator.distanceBetween(
            _posicaoAtual!.latitude,
            _posicaoAtual!.longitude,
            latitude,
            longitude,
          );

          distanciaKm =
              distanciaMetros / 1000;
        }

        final marca =
            veiculo['marca']
                    ?.toString() ??
                '';

        final modelo =
            veiculo['modelo']
                    ?.toString() ??
                '';

        final veiculoTexto = [
          marca,
          modelo,
        ]
            .where(
              (valor) =>
                  valor
                      .trim()
                      .isNotEmpty,
            )
            .join(' ');

        DateTime criadoEm =
            DateTime.now();

        final dataRaw =
            item['created_at']
                ?.toString();

        if (dataRaw != null) {
          try {
            criadoEm =
                DateTime.parse(
              dataRaw.replaceFirst(
                ' ',
                'T',
              ),
            );
          } catch (_) {}
        }

        lista.add(
          ChamadoDisponivel(
            id: _paraInt(
              item['id'],
            ),
            nomeUsuario:
                cliente['nome']
                        ?.toString() ??
                    'Cliente',
            telefoneUsuario:
                cliente['telefone']
                    ?.toString(),
            servico:
                item['tipo_reboque']
                        ?.toString() ??
                    'Guincho',
            distanciaKm:
                distanciaKm,
            endereco:
                item['endereco']
                        ?.toString() ??
                    '',
            latitude:
                latitude,
            longitude:
                longitude,
            valorEstimado:
                _paraDouble(
              item['valor_estimado'],
            ),
            formaPagamento:
                item['forma_pagamento']
                        ?.toString() ??
                    '',
            veiculo:
                veiculoTexto.isEmpty
                    ? 'Veículo'
                    : veiculoTexto,
            placaVeiculo:
                veiculo['placa']
                    ?.toString(),
            criadoEm:
                criadoEm,
          ),
        );
      }

      // Mais próximos primeiro.
      lista.sort(
        (a, b) =>
            a.distanciaKm.compareTo(
          b.distanciaKm,
        ),
      );

      setState(() {
        _chamados
          ..clear()
          ..addAll(lista);

        _erroBusca = false;
      });
    } on ApiException {
      if (!mounted) return;

      setState(() {
        _erroBusca = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _erroBusca = true;
      });
    } finally {
      _buscandoChamados = false;
    }
  }

  // ============================================================
  // ACEITAR CHAMADO
  // ============================================================

  Future<void> _aceitarChamado(
    ChamadoDisponivel chamado,
  ) async {
    if (_aceitandoChamado) return;

    final confirmar =
        await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) =>
          _ModalConfirmarAceite(
        chamado: chamado,
      ),
    );

    if (confirmar != true ||
        !mounted) {
      return;
    }

    setState(() {
      _aceitandoChamado = true;
    });

    try {
      // Aceita no banco.
      await ApiService.instance
          .aceitarSolicitacao(
        solicitacaoId:
            chamado.id,
      );

      // Assim que aceitar,
      // passa para a caminho.
      await ApiService.instance
          .atualizarStatus(
        solicitacaoId:
            chamado.id,
        status:
            'a_caminho',
      );

      final position =
          await _obterLocalizacao();

      if (position != null) {
        await ApiService.instance
            .atualizarLocalizacao(
          latitude:
              position.latitude,
          longitude:
              position.longitude,
        );
      }

      if (!mounted) return;

      _pollingTimer?.cancel();

      setState(() {
        _aceitandoChamado = false;
      });

      final coordenadaMotorista =
          position != null
              ? LatLng(
                  position.latitude,
                  position.longitude,
                )
              : LatLng(
                  chamado.latitude +
                      0.005,
                  chamado.longitude +
                      0.005,
                );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RotaSocorristaScreen(
            chamado:
                ChamadoAceito(
              id:
                  chamado.id,
              nomeUsuario:
                  chamado.nomeUsuario,
              servico:
                  chamado.servico,
              coordenadaUsuario:
                  LatLng(
                chamado.latitude,
                chamado.longitude,
              ),
              enderecoUsuario:
                  chamado.endereco,
              distanciaKm:
                  chamado.distanciaKm,
            ),
            coordenadaSocorrista:
                coordenadaMotorista,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _aceitandoChamado = false;
      });

      // Pode ter sido aceita por
      // outro motorista.
      await _buscarChamados(
        mostrarCarregamento: false,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.mensagem,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _aceitandoChamado = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível aceitar o chamado.',
          ),
        ),
      );
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
      backgroundColor:
          cinzaFundo,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            if (_tabIndex != 2)
              _buildToggleOnline(),

            Expanded(
              child: _tabIndex == 0
                  ? _buildListaChamados()
                  : _tabIndex == 1
                      ? _buildHistorico()
                      : PerfilSocorristaScreen(
                          nome:
                              _nomeSocorrista,
                          tipoAtuacao:
                              _tipoAtuacao,
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          _buildBottomNav(),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final inicial =
        _nomeSocorrista.isNotEmpty
            ? _nomeSocorrista[0]
                .toUpperCase()
            : 'M';

    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        24,
        16,
        24,
        12,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              gradient:
                  const LinearGradient(
                colors: [
                  Color(
                    0xFF2E8FF7,
                  ),
                  Color(
                    0xFF1565D8,
                  ),
                ],
                begin:
                    Alignment.topLeft,
                end:
                    Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Center(
              child: Text(
                inicial,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
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
                Text(
                  'Olá, ${_nomeSocorrista.split(' ').first}',
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        pretoPrincipal,
                  ),
                ),
                Text(
                  _tipoAtuacao,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    color: cinzaTexto,
                  ),
                ),
              ],
            ),
          ),

          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon:
                    const Icon(
                  Icons
                      .notifications_outlined,
                  color:
                      pretoPrincipal,
                  size: 24,
                ),
              ),

              if (_chamados
                  .isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(
                        0xFFEF4444,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOGGLE ONLINE
  // ============================================================

  Widget _buildToggleOnline() {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        8,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.05,
            ),
            blurRadius: 10,
            offset:
                const Offset(
              0,
              2,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 300,
            ),
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,
              color: _carregando
                  ? cinzaTexto
                  : (_online
                      ? verdeOnline
                      : cinzaOffline),
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
                Text(
                  _carregando
                      ? 'Atualizando...'
                      : (_online
                          ? 'Você está online'
                          : 'Você está offline'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                    color: _online
                        ? pretoPrincipal
                        : cinzaTexto,
                  ),
                ),
                Text(
                  _online
                      ? 'Recebendo solicitações de guincho'
                      : 'Ative para receber chamados',
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        cinzaTexto,
                  ),
                ),
              ],
            ),
          ),

          _carregando
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                        azulPrincipal,
                  ),
                )
              : Switch(
                  value:
                      _online,
                  onChanged:
                      _toggleOnline,
                  activeThumbColor:
                      verdeOnline,
                ),
        ],
      ),
    );
  }

  // ============================================================
  // LISTA
  // ============================================================

  Widget _buildListaChamados() {
    if (!_online) {
      return _buildEstadoVazio(
        icon:
            Icons.wifi_off_rounded,
        titulo:
            'Você está offline',
        subtitulo:
            'Ative o botão acima para\ncomeçar a receber chamados.',
      );
    }

    if (_erroBusca &&
        _chamados.isEmpty) {
      return _buildEstadoVazio(
        icon:
            Icons.cloud_off_rounded,
        titulo:
            'Erro ao buscar chamados',
        subtitulo:
            'Não foi possível consultar o servidor.\nTentaremos novamente automaticamente.',
      );
    }

    if (_chamados.isEmpty) {
      return _buildEstadoVazio(
        icon:
            Icons.search_off_rounded,
        titulo:
            'Nenhum chamado por perto',
        subtitulo:
            'Aguarde. Novas solicitações\naparecerão automaticamente.',
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            24,
            12,
            24,
            8,
          ),
          child: Row(
            children: [
              Text(
                '${_chamados.length} chamado${_chamados.length > 1 ? 's' : ''} disponível${_chamados.length > 1 ? 'is' : ''}',
                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      pretoPrincipal,
                ),
              ),

              const Spacer(),

              const Text(
                'Mais próximos primeiro',
                style:
                    TextStyle(
                  fontSize: 12,
                  color:
                      cinzaTexto,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child:
              ListView.separated(
            padding:
                const EdgeInsets
                    .fromLTRB(
              20,
              0,
              20,
              24,
            ),
            itemCount:
                _chamados.length,
            separatorBuilder:
                (_, _) =>
                    const SizedBox(
              height: 12,
            ),
            itemBuilder:
                (_, index) {
              final chamado =
                  _chamados[index];

              return _CardChamado(
                chamado:
                    chamado,
                aceitando:
                    _aceitandoChamado,
                onAceitar: () {
                  _aceitarChamado(
                    chamado,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HISTÓRICO
  // ============================================================

  Widget _buildHistorico() {
    return _buildEstadoVazio(
      icon:
          Icons.history_rounded,
      titulo:
          'Histórico de atendimentos',
      subtitulo:
          'Seus chamados concluídos\naparecerão aqui.',
    );
  }

  // ============================================================
  // ESTADO VAZIO
  // ============================================================

  Widget _buildEstadoVazio({
    required IconData icon,
    required String titulo,
    required String subtitulo,
  }) {
    return Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration:
                BoxDecoration(
              color: Colors.white,
              shape:
                  BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(
                    alpha: 0.06,
                  ),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 32,
              color: cinzaTexto,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            titulo,
            style:
                const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w700,
              color:
                  pretoPrincipal,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            subtitulo,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 14,
              color:
                  cinzaTexto,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV
  // ============================================================

  Widget _buildBottomNav() {
    return Container(
      decoration:
          const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color:
                Color(
              0xFFEEEEEE,
            ),
            width: 1,
          ),
        ),
      ),
      child:
          BottomNavigationBar(
        currentIndex:
            _tabIndex,
        onTap: (i) {
          setState(() {
            _tabIndex = i;
          });
        },
        backgroundColor:
            Colors.white,
        selectedItemColor:
            azulPrincipal,
        unselectedItemColor:
            cinzaTexto,
        elevation: 0,
        selectedLabelStyle:
            const TextStyle(
          fontSize: 12,
          fontWeight:
              FontWeight.w600,
        ),
        unselectedLabelStyle:
            const TextStyle(
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
            ),
            activeIcon: Icon(
              Icons.home_rounded,
            ),
            label:
                'Chamados',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.history_outlined,
            ),
            activeIcon: Icon(
              Icons.history_rounded,
            ),
            label:
                'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons
                  .person_outline_rounded,
            ),
            activeIcon: Icon(
              Icons.person_rounded,
            ),
            label:
                'Perfil',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AUXILIARES
  // ============================================================

  int _paraInt(
    dynamic valor,
  ) {
    if (valor is int) {
      return valor;
    }

    return int.tryParse(
          valor?.toString() ?? '',
        ) ??
        0;
  }

  double _paraDouble(
    dynamic valor,
  ) {
    if (valor is double) {
      return valor;
    }

    if (valor is int) {
      return valor.toDouble();
    }

    return double.tryParse(
          valor?.toString() ?? '',
        ) ??
        0;
  }
}

// ============================================================
// CARD DO CHAMADO
// ============================================================

class _CardChamado
    extends StatelessWidget {
  final ChamadoDisponivel chamado;

  final VoidCallback onAceitar;

  final bool aceitando;

  static const Color azulPrincipal =
      Color(0xFF1A7EF5);

  static const Color cinzaTexto =
      Color(0xFF8A8A8A);

  static const Color pretoPrincipal =
      Color(0xFF1A1A1A);

  const _CardChamado({
    required this.chamado,
    required this.onAceitar,
    required this.aceitando,
  });

  String get _tempoAtras {
    final diff =
        DateTime.now()
            .difference(
              chamado.criadoEm,
            )
            .inMinutes;

    if (diff < 1) {
      return 'agora';
    }

    if (diff == 1) {
      return 'há 1 min';
    }

    return 'há $diff min';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.05,
            ),
            blurRadius: 10,
            offset:
                const Offset(
              0,
              2,
            ),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration:
                      BoxDecoration(
                    color:
                        azulPrincipal
                            .withValues(
                      alpha: 0.1,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      11,
                    ),
                  ),
                  child:
                      const Icon(
                    Icons
                        .local_shipping_rounded,
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
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        chamado
                            .nomeUsuario,
                        style:
                            const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight
                                  .w700,
                          color:
                              pretoPrincipal,
                        ),
                      ),
                      Text(
                        chamado.servico,
                        style:
                            const TextStyle(
                          fontSize: 13,
                          color:
                              cinzaTexto,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  _tempoAtras,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        cinzaTexto,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            const Divider(
              height: 1,
              color:
                  Color(
                0xFFF0F0F0,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons
                      .location_on_outlined,
                  size: 16,
                  color:
                      cinzaTexto,
                ),

                const SizedBox(
                  width: 6,
                ),

                Expanded(
                  child: Text(
                    chamado.endereco,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color:
                          cinzaTexto,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFF0F7FF,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),
                  child: Text(
                    '${chamado.distanciaKm.toStringAsFixed(1)} km',
                    style:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight
                              .w700,
                      color:
                          azulPrincipal,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            Row(
              children: [
                const Icon(
                  Icons
                      .directions_car_outlined,
                  size: 16,
                  color:
                      cinzaTexto,
                ),

                const SizedBox(
                  width: 6,
                ),

                Expanded(
                  child: Text(
                    chamado
                            .placaVeiculo !=
                        null
                        ? '${chamado.veiculo} • ${chamado.placaVeiculo}'
                        : chamado
                            .veiculo,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color:
                          cinzaTexto,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            Row(
              children: [
                Text(
                  chamado
                      .formaPagamento,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        cinzaTexto,
                  ),
                ),

                const Spacer(),

                Text(
                  'R\$ ${chamado.valorEstimado.toStringAsFixed(2).replaceAll('.', ',')}',
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        pretoPrincipal,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            SizedBox(
              width: double.infinity,
              height: 44,
              child:
                  ElevatedButton(
                onPressed:
                    aceitando
                        ? null
                        : onAceitar,
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      azulPrincipal,
                  foregroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                  ),
                  elevation: 0,
                ),
                child: aceitando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          color:
                              Colors.white,
                          strokeWidth:
                              2,
                        ),
                      )
                    : const Text(
                        'Aceitar chamado',
                        style:
                            TextStyle(
                          fontSize: 14,
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
    );
  }
}

// ============================================================
// MODAL DE CONFIRMAÇÃO
// ============================================================

class _ModalConfirmarAceite
    extends StatelessWidget {
  final ChamadoDisponivel chamado;

  static const Color azulPrincipal =
      Color(0xFF1A7EF5);

  static const Color cinzaTexto =
      Color(0xFF8A8A8A);

  static const Color pretoPrincipal =
      Color(0xFF1A1A1A);

  const _ModalConfirmarAceite({
    required this.chamado,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        24,
        20,
        24,
        36,
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFE0E0E0,
                ),
                borderRadius:
                    BorderRadius
                        .circular(
                  2,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          const Text(
            'Confirmar aceite',
            style:
                TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              color:
                  pretoPrincipal,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          const Text(
            'Ao aceitar, você se compromete a atender este chamado.',
            style:
                TextStyle(
              fontSize: 14,
              color:
                  cinzaTexto,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Container(
            padding:
                const EdgeInsets.all(
              16,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF5F5F5,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Column(
              children: [
                _buildLinha(
                  Icons
                      .person_outline_rounded,
                  'Usuário',
                  chamado
                      .nomeUsuario,
                ),

                const SizedBox(
                  height: 10,
                ),

                _buildLinha(
                  Icons
                      .local_shipping_outlined,
                  'Serviço',
                  chamado.servico,
                ),

                const SizedBox(
                  height: 10,
                ),

                _buildLinha(
                  Icons
                      .location_on_outlined,
                  'Local',
                  chamado.endereco,
                ),

                const SizedBox(
                  height: 10,
                ),

                _buildLinha(
                  Icons
                      .directions_car_outlined,
                  'Distância',
                  '${chamado.distanciaKm.toStringAsFixed(1)} km de você',
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      false,
                    );
                  },
                  style:
                      OutlinedButton
                          .styleFrom(
                    foregroundColor:
                        cinzaTexto,
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
                        10,
                      ),
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 14,
                    ),
                  ),
                  child:
                      const Text(
                    'Cancelar',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                flex: 2,
                child:
                    ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      true,
                    );
                  },
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        azulPrincipal,
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        10,
                      ),
                    ),
                    elevation: 0,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 14,
                    ),
                  ),
                  child:
                      const Text(
                    'Confirmar aceite',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinha(
    IconData icon,
    String label,
    String valor,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: cinzaTexto,
        ),

        const SizedBox(
          width: 8,
        ),

        Text(
          '$label: ',
          style:
              const TextStyle(
            fontSize: 13,
            color:
                cinzaTexto,
            fontWeight:
                FontWeight.w500,
          ),
        ),

        Expanded(
          child: Text(
            valor,
            style:
                const TextStyle(
              fontSize: 13,
              color:
                  pretoPrincipal,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}