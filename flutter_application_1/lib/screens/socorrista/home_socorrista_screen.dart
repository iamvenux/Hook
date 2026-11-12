import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_application_1/controllers/socorrista_controller.dart';
import 'package:flutter_application_1/models/api_exception.dart';
import 'package:flutter_application_1/models/chamado_aceito.dart';
import 'package:flutter_application_1/models/chamado_disponivel.dart';
import 'package:flutter_application_1/screens/socorrista/perfil_socorrista_screen.dart';
import 'package:flutter_application_1/screens/socorrista/ganhos_screen.dart';
import 'package:flutter_application_1/screens/socorrista/rota_socorrista_screen.dart';
import 'package:flutter_application_1/services/localizacao_service.dart';
import 'package:flutter_application_1/widgets/card_chamado.dart';
import 'package:flutter_application_1/widgets/modal_confirmar_aceite.dart';

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

  final SocorristaController _controller =
      SocorristaController.instance;

  final LocalizacaoService _localizacao =
      LocalizacaoService.instance;

  // ============================================================
  // DADOS DO MOTORISTA LOGADO
  // ============================================================

  String get _nomeSocorrista {
    return _controller.nomeSocorrista;
  }

  String get _tipoAtuacao {
    return _controller.tipoAtuacao;
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
    final status =
        await _localizacao.verificarPermissao();

    if (status == StatusLocalizacao.permitido) {
      return true;
    }

    if (!mounted) return false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == StatusLocalizacao.servicoDesativado
              ? 'Ative a localização do dispositivo.'
              : 'Permissão de localização necessária.',
        ),
      ),
    );

    return false;
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
          await _localizacao.obterPosicaoAtual();

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

        // Salva a posição inicial no banco e
        // deixa o motorista disponível.
        await _controller.ficarOnline(position);

        if (!mounted) return;

        setState(() {
          _online = true;
          _carregando = false;
        });

        await _buscarChamados();

        _iniciarPolling();
      } else {
        _pollingTimer?.cancel();

        await _controller.ficarOffline();

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
          await _controller.buscarSolicitacoes();

      if (!mounted) return;

      // Atualiza posição do motorista
      // de tempos em tempos.
      final position =
          await _obterLocalizacao();

      if (position != null) {
        try {
          await _controller.enviarLocalizacao(
            position,
          );
        } catch (_) {
          // Não bloqueia a lista por erro
          // de atualização da localização.
        }
      }

      // Já vem ordenada: mais próximos primeiro.
      final lista = _controller.montarChamados(
        resultado,
        posicaoAtual: _posicaoAtual,
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
          ModalConfirmarAceite(
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
      // Aceita no banco e, assim que aceitar,
      // passa para a caminho.
      await _controller.aceitarChamado(
        chamado.id,
      );

      final position =
          await _obterLocalizacao();

      if (position != null) {
        await _controller.enviarLocalizacao(
          position,
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
                          // Atualiza o nome no cabeçalho
                          // depois de editar os dados.
                          onPerfilAtualizado: () {
                            setState(() {});
                          },
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

              return CardChamado(
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
    // Atendimentos concluídos com os valores recebidos
    // (a mesma tela de "Ganhos e repasses" do perfil).
    return const GanhosScreen(
      embutido: true,
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
}
