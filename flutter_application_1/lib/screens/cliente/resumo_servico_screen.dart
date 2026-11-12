import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_application_1/controllers/auth_controller.dart';
import 'package:flutter_application_1/controllers/solicitacao_controller.dart';
import 'package:flutter_application_1/models/api_exception.dart';
import 'package:flutter_application_1/models/servico_config.dart';
import 'package:flutter_application_1/screens/cliente/procurando_profissional_screen.dart';
import 'package:flutter_application_1/widgets/endereco_overlay.dart';

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

    // Forma escolhida em "Perfil > Forma de pagamento".
    _formaPagamento = AuthController.instance.formaPagamentoPadrao;
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _trocoController.dispose();
    super.dispose();
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
      trocoPara = SolicitacaoController.parseValorMonetario(
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
          SolicitacaoController.parseValorMonetario(
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
      final solicitacaoId =
          await SolicitacaoController.instance.criarSolicitacao(
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
