import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'overlay_endereco.dart';
import 'api_service.dart';

// ─────────────────────────────────────────────
// CONFIGURAÇÃO DOS SERVIÇOS
// ─────────────────────────────────────────────

enum CategoriaServico { reboque, ajuda }

class ServicoConfig {
  final CategoriaServico categoria;
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final String valorEstimado;
  final bool exigeDescricao;

  const ServicoConfig({
    required this.categoria,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.valorEstimado,
    this.exigeDescricao = false,
  });

  bool get isReboque => categoria == CategoriaServico.reboque;

  String get tituloResumo =>
      isReboque ? 'RESUMO DO SERVIÇO' : 'SOLICITAR AJUDA';

  String get labelBotaoResumo =>
      isReboque ? 'Solicitar guincho' : 'Solicitar Ajuda';

  String get labelProfissional =>
      isReboque ? 'guincho' : 'socorrista';
}

const Map<String, ServicoConfig> tiposDeReboque = {
  'Guincho Leve': ServicoConfig(
    categoria: CategoriaServico.reboque,
    titulo: 'Guincho Leve',
    subtitulo: 'Até 3.5 toneladas',
    icone: Icons.local_shipping_rounded,
    valorEstimado: 'R\$ 350,00',
  ),
  'Guincho Pesado': ServicoConfig(
    categoria: CategoriaServico.reboque,
    titulo: 'Guincho Pesado',
    subtitulo: 'Caminhões e ônibus',
    icone: Icons.rv_hookup_rounded,
    valorEstimado: 'R\$ 550,00',
  ),
};

const Map<String, ServicoConfig> tiposDeAjuda = {
  'Pneu Furado': ServicoConfig(
    categoria: CategoriaServico.ajuda,
    titulo: 'Pneu Furado',
    subtitulo: 'Troca ou reparo emergencial',
    icone: Icons.tire_repair_rounded,
    valorEstimado: 'R\$ 120,00',
  ),
  'Falta de Combustível': ServicoConfig(
    categoria: CategoriaServico.ajuda,
    titulo: 'Falta de Combustível',
    subtitulo: 'Auxílio para pane seca',
    icone: Icons.local_gas_station_rounded,
    valorEstimado: 'R\$ 90,00',
  ),
  'Bateria Descarregada': ServicoConfig(
    categoria: CategoriaServico.ajuda,
    titulo: 'Bateria Descarregada',
    subtitulo: 'Carga auxiliar e diagnóstico rápido',
    icone: Icons.battery_charging_full_rounded,
    valorEstimado: 'R\$ 100,00',
  ),
  'Outros': ServicoConfig(
    categoria: CategoriaServico.ajuda,
    titulo: 'Outros',
    subtitulo: 'Descreva a ajuda necessária',
    icone: Icons.build_rounded,
    valorEstimado: 'A combinar',
    exigeDescricao: true,
  ),
};

// ─────────────────────────────────────────────
// TELA 1 — RESUMO DO SERVIÇO
// ─────────────────────────────────────────────

class ResumoServicoScreen extends StatefulWidget {
  final ServicoConfig servico;
  final String endereco;
  final LatLng coordenada;
  final String veiculo;
  final int veiculoId;

  const ResumoServicoScreen({
    super.key,
    required this.servico,
    required this.endereco,
    required this.coordenada,
    required this.veiculo,
    required this.veiculoId,
  });

  @override
  State<ResumoServicoScreen> createState() =>
      _ResumoServicoScreenState();
}

class _ResumoServicoScreenState
    extends State<ResumoServicoScreen> {
  static const Color azulPrincipal = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto = Color(0xFF8A8A8A);
  static const Color cinzaFundo = Color(0xFFF5F5F5);

  String _formaPagamento = 'Pix';

  bool _precisaTroco = false;

  final TextEditingController _trocoController =
      TextEditingController();

  late String _endereco;
  late LatLng _coordenada;

  final _descricaoController = TextEditingController();

  bool _tentouEnviar = false;
  bool _enviando = false;

  final Map<String, String> _formasPagamento = {
    'Pix': 'Pagamento instantâneo',
    'Dinheiro': 'Pagamento em espécie',
  };

  ServicoConfig get _servico => widget.servico;

  @override
  void initState() {
    super.initState();

    _endereco = widget.endereco;
    _coordenada = widget.coordenada;
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _trocoController.dispose();
    super.dispose();
  }

  double? _parseValorMonetario(String valor) {
    var texto = valor
        .trim()
        .replaceAll('R\$', '')
        .replaceAll(' ', '');

    if (texto.isEmpty) {
      return null;
    }

    if (texto.contains(',')) {
      texto = texto
          .replaceAll('.', '')
          .replaceAll(',', '.');
    }

    return double.tryParse(texto);
  }

  Future<void> _confirmarSolicitacao() async {
    if (_servico.exigeDescricao &&
        _descricaoController.text.trim().isEmpty) {
      setState(() {
        _tentouEnviar = true;
      });

      return;
    }

    // Seu banco atual só aceita Guincho Leve/Pesado.
    if (!_servico.isReboque) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Os serviços de ajuda ainda não estão integrados ao backend.',
          ),
        ),
      );

      return;
    }

    double? trocoPara;

    if (_formaPagamento == 'Dinheiro' &&
        _precisaTroco) {
      trocoPara = _parseValorMonetario(
        _trocoController.text,
      );

      if (trocoPara == null ||
          trocoPara <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Informe para quanto precisa de troco.',
            ),
          ),
        );

        return;
      }

      final valorEstimado =
          _parseValorMonetario(
        _servico.valorEstimado,
      );

      if (valorEstimado != null &&
          trocoPara <= valorEstimado) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'O valor para troco deve ser maior que '
              '${_servico.valorEstimado}.',
            ),
          ),
        );

        return;
      }
    }

    setState(() {
      _enviando = true;
    });

    try {
      final solicitacao =
          await ApiService.instance.criarSolicitacao(
        veiculoId: widget.veiculoId,
        tipoReboque: _servico.titulo,
        formaPagamento: _formaPagamento,
        endereco: _endereco,
        latitude: _coordenada.latitude,
        longitude: _coordenada.longitude,
        precisaTroco:
            _formaPagamento == 'Dinheiro'
                ? _precisaTroco
                : false,
        trocoPara:
            _formaPagamento == 'Dinheiro' &&
                    _precisaTroco
                ? trocoPara
                : null,
      );

      if (!mounted) return;

      final idRaw =
          solicitacao['id'] ??
          (solicitacao['solicitacao']
                  as Map?)?['id'];

      final solicitacaoId =
          idRaw is int
              ? idRaw
              : int.tryParse(
                  idRaw.toString(),
                );

      if (solicitacaoId == null) {
        throw ApiException(
          'O servidor não retornou o ID da solicitação.',
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProcurandoProfissionalScreen(
            servico: _servico,
            endereco: _endereco,
            coordenada: _coordenada,
            veiculo: widget.veiculo,
            solicitacaoId:
                solicitacaoId,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _enviando = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.mensagem),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _enviando = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível conectar ao servidor.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _coordenada,
              zoom: 14,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('encontro'),
                position: _coordenada,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
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
                  width: 42,
                  height: 42,
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
                  child: const Icon(
                    Icons.arrow_back,
                    color: pretoPrincipal,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F7),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                20,
                28,
                20,
                0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _servico.tituloResumo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: pretoPrincipal,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: azulPrincipal
                                  .withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _servico.icone,
                              color: azulPrincipal,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _servico.titulo,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: pretoPrincipal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _servico.subtitulo,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: cinzaTexto,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () async {
                        final resultado =
                            await showGeneralDialog<dynamic>(
                          context: context,
                          barrierDismissible: false,
                          barrierColor: Colors.transparent,
                          transitionDuration: Duration.zero,
                          pageBuilder: (_, __, ___) =>
                              EnderecoOverlay(
                            enderecoAtual: _endereco,
                            coordenadaAtual: _coordenada,
                          ),
                        );

                        if (resultado != null && mounted) {
                          final r =
                              resultado as Map<String, dynamic>;

                          setState(() {
                            _endereco =
                                r['endereco'] as String;

                            _coordenada = LatLng(
                              r['lat'] as double,
                              r['lng'] as double,
                            );
                          });
                        }
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration:
                                  const BoxDecoration(
                                color: pretoPrincipal,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PONTO DE ENCONTRO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: azulPrincipal,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _endereco,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w500,
                                      color: pretoPrincipal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: azulPrincipal
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Alterar',
                                style: TextStyle(
                                  color: azulPrincipal,
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cinzaFundo,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.directions_car_rounded,
                              color: pretoPrincipal,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'VEÍCULO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: cinzaTexto,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.veiculo,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w600,
                                    color: pretoPrincipal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_servico.exigeDescricao) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: _tentouEnviar &&
                                    _descricaoController
                                        .text
                                        .trim()
                                        .isEmpty
                                ? Colors.red
                                : Colors.transparent,
                            width: 1.4,
                          ),
                        ),
                        child: TextField(
                          controller:
                              _descricaoController,
                          maxLines: 3,
                          minLines: 2,
                          style: const TextStyle(
                            fontSize: 14,
                            color: pretoPrincipal,
                          ),
                          decoration:
                              const InputDecoration(
                            hintText:
                                'Descreva o problema com o veículo...',
                            hintStyle: TextStyle(
                              color: cinzaTexto,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Valor estimado',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w500,
                                    color: pretoPrincipal,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _servico.isReboque
                                      ? 'Pode variar conforme distância\ne tempo de espera'
                                      : 'Pode variar conforme o serviço\nrealizado no local',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: cinzaTexto,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _servico.valorEstimado,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight:
                                    FontWeight.w800,
                                color: azulPrincipal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () =>
                          _mostrarAlterarPagamento(context),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: azulPrincipal
                                .withOpacity(0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cinzaFundo,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.payment_rounded,
                                color: pretoPrincipal,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formaPagamento,
                                    style:
                                        const TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w600,
                                      color:
                                          pretoPrincipal,
                                    ),
                                  ),
                                  Text(
                                    _formasPagamento[
                                        _formaPagamento]!,
                                    style:
                                        const TextStyle(
                                      fontSize: 12,
                                      color: cinzaTexto,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: azulPrincipal
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Alterar',
                                style: TextStyle(
                                  color: azulPrincipal,
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_formaPagamento == 'Dinheiro') ...[
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: cinzaFundo,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons
                                        .currency_exchange_rounded,
                                    color: pretoPrincipal,
                                    size: 21,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Precisa de troco?',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w600,
                                          color:
                                              pretoPrincipal,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Informe se o motorista deve levar troco',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cinzaTexto,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Switch(
                                  value: _precisaTroco,
                                  activeTrackColor:
                                      azulPrincipal.withValues(
                                    alpha: 0.45,
                                  ),
                                  activeThumbColor:
                                      azulPrincipal,
                                  onChanged: (valor) {
                                    setState(() {
                                      _precisaTroco =
                                          valor;

                                      if (!valor) {
                                        _trocoController
                                            .clear();
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),

                            if (_precisaTroco) ...[
                              const SizedBox(height: 14),

                              TextField(
                                controller:
                                    _trocoController,
                                keyboardType:
                                    const TextInputType
                                        .numberWithOptions(
                                  decimal: true,
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: pretoPrincipal,
                                ),
                                decoration:
                                    InputDecoration(
                                  labelText:
                                      'Troco para quanto?',
                                  hintText: 'Ex: 500,00',
                                  prefixText: 'R\$ ',
                                  filled: true,
                                  fillColor: cinzaFundo,
                                  labelStyle:
                                      const TextStyle(
                                    color: cinzaTexto,
                                  ),
                                  hintStyle:
                                      const TextStyle(
                                    color: cinzaTexto,
                                  ),
                                  enabledBorder:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      12,
                                    ),
                                    borderSide:
                                        BorderSide.none,
                                  ),
                                  focusedBorder:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      12,
                                    ),
                                    borderSide:
                                        const BorderSide(
                                      color:
                                          azulPrincipal,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'Exemplo: se você vai pagar com R\$ 500,00, informe 500,00.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cinzaTexto,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SafeArea(
                      top: false,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _enviando
                                ? null
                                : _confirmarSolicitacao,
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  pretoPrincipal,
                              foregroundColor:
                                  Colors.white,
                              disabledBackgroundColor:
                                  pretoPrincipal
                                      .withOpacity(0.6),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  28,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: _enviando
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    _servico
                                        .labelBotaoResumo,
                                    style:
                                        const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
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
        ],
      ),
    );
  }

  void _mostrarAlterarPagamento(
      BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Forma de pagamento',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: pretoPrincipal,
                ),
              ),
              const SizedBox(height: 16),
              ..._formasPagamento.entries.map((e) {
                final selecionado =
                    _formaPagamento == e.key;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _formaPagamento = e.key;

                      if (_formaPagamento !=
                          'Dinheiro') {
                        _precisaTroco = false;
                        _trocoController.clear();
                      }
                    });

                    Navigator.pop(context);
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: selecionado
                          ? azulPrincipal
                              .withOpacity(0.07)
                          : cinzaFundo,
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color: selecionado
                            ? azulPrincipal
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.key,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.w600,
                                  color: selecionado
                                      ? azulPrincipal
                                      : pretoPrincipal,
                                ),
                              ),
                              Text(
                                e.value,
                                style:
                                    const TextStyle(
                                  fontSize: 12,
                                  color: cinzaTexto,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selecionado)
                          const Icon(
                            Icons
                                .check_circle_rounded,
                            color: azulPrincipal,
                            size: 20,
                          ),
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
          await ApiService.instance.consultarSolicitacao(
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
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origem.longitude},${origem.latitude};'
      '${destino.longitude},${destino.latitude}'
      '?overview=full&geometries=polyline',
    );

    try {
      final response =
          await http.get(url);

      if (response.statusCode != 200) {
        return;
      }

      final data =
          json.decode(response.body)
              as Map<String, dynamic>;

      if (data['code'] != 'Ok') {
        return;
      }

      final routes =
          data['routes'] as List;

      if (routes.isEmpty) {
        return;
      }

      final pontos =
          _decodePolyline(
        routes[0]['geometry'] as String,
      );

      if (!mounted) return;

      setState(() {
        _polylines = {
          Polyline(
            polylineId:
                const PolylineId(
              'rota_profissional',
            ),
            points: pontos,
            color: azulPrincipal,
            width: 5,
          ),
        };
      });
    } catch (_) {
      // Se o OSRM falhar,
      // o acompanhamento continua funcionando.
    }
  }

  // ─────────────────────────────────────────────
  // DECODIFICAR POLYLINE
  // ─────────────────────────────────────────────

  List<LatLng> _decodePolyline(
    String encoded,
  ) {
    final result = <LatLng>[];

    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result0 = 0;
      int b;

      do {
        b =
            encoded.codeUnitAt(index++) -
                63;

        result0 |=
            (b & 0x1f) << shift;

        shift += 5;
      } while (b >= 0x20);

      lat += (result0 & 1) != 0
          ? ~(result0 >> 1)
          : (result0 >> 1);

      shift = 0;
      result0 = 0;

      do {
        b =
            encoded.codeUnitAt(index++) -
                63;

        result0 |=
            (b & 0x1f) << shift;

        shift += 5;
      } while (b >= 0x20);

      lng += (result0 & 1) != 0
          ? ~(result0 >> 1)
          : (result0 >> 1);

      result.add(
        LatLng(
          lat / 1e5,
          lng / 1e5,
        ),
      );
    }

    return result;
  }

  // ─────────────────────────────────────────────
  // CANCELAR
  // ─────────────────────────────────────────────

  Future<void> _cancelar() async {
    _pollingTimer?.cancel();

    try {
      await ApiService.instance
          .cancelarSolicitacao(
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

          Positioned(
            bottom:
                paddingInferiorMapa + 190,
            left: 20,
            child: FloatingActionButton(
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