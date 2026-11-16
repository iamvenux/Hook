import 'package:flutter/material.dart';

import 'api_service.dart';

class HistoricoClienteScreen
    extends StatefulWidget {
  const HistoricoClienteScreen({
    super.key,
  });

  @override
  State<HistoricoClienteScreen>
      createState() =>
          _HistoricoClienteScreenState();
}

class _HistoricoClienteScreenState
    extends State<HistoricoClienteScreen> {
  static const Color azulPrincipal =
      Color(0xFF1A7EF5);

  static const Color pretoPrincipal =
      Color(0xFF1A1A1A);

  static const Color cinzaTexto =
      Color(0xFF8A8A8A);

  static const Color cinzaFundo =
      Color(0xFFF5F5F5);

  bool _carregando = true;

  List<Map<String, dynamic>>
      _historico = [];

  @override
  void initState() {
    super.initState();

    _carregar();
  }

  Future<void> _carregar() async {
    if (mounted) {
      setState(() {
        _carregando = true;
      });
    }

    try {
      final lista =
          await ApiService.instance
              .listarHistorico();

      if (!mounted) return;

      setState(() {
        _historico = lista;
        _carregando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.mensagem),
        ),
      );
    }
  }

  String _nomeStatus(
    String status,
  ) {
    switch (status) {
      case 'buscando':
        return 'Buscando';

      case 'aceito':
        return 'Aceito';

      case 'a_caminho':
        return 'A caminho';

      case 'no_local':
        return 'No local';

      case 'em_atendimento':
        return 'Em atendimento';

      case 'concluido':
        return 'Concluído';

      case 'cancelado':
        return 'Cancelado';

      default:
        return status;
    }
  }

  Color _corStatus(
    String status,
  ) {
    switch (status) {
      case 'concluido':
        return Colors.green;

      case 'cancelado':
        return Colors.red;

      case 'em_atendimento':
        return Colors.purple;

      case 'no_local':
        return Colors.orange;

      default:
        return azulPrincipal;
    }
  }

  String _formatarData(
    String data,
  ) {
    try {
      final date =
          DateTime.parse(
        data.replaceFirst(
          ' ',
          'T',
        ),
      );

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          'às '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return data;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Padding(
            padding:
                EdgeInsets.fromLTRB(
              24,
              28,
              24,
              4,
            ),
            child: Text(
              'Histórico',
              style: TextStyle(
                fontSize: 26,
                fontWeight:
                    FontWeight.bold,
                color:
                    pretoPrincipal,
              ),
            ),
          ),

          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Text(
              'Acompanhe todos os seus resgates',
              style: TextStyle(
                fontSize: 14,
                color:
                    cinzaTexto,
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Expanded(
            child: _carregando
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          azulPrincipal,
                    ),
                  )
                : _historico.isEmpty
                    ? const Center(
                        child:
                            Column(
                          mainAxisSize:
                              MainAxisSize
                                  .min,
                          children: [
                            Icon(
                              Icons
                                  .history_rounded,
                              size:
                                  54,
                              color:
                                  cinzaTexto,
                            ),
                            SizedBox(
                              height:
                                  12,
                            ),
                            Text(
                              'Nenhum resgate encontrado.',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh:
                            _carregar,
                        child:
                            ListView
                                .separated(
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            20,
                            0,
                            20,
                            24,
                          ),
                          itemCount:
                              _historico
                                  .length,
                          separatorBuilder:
                              (_, _) =>
                                  const SizedBox(
                            height: 12,
                          ),
                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            final item =
                                _historico[
                                    index];

                            final veiculoRaw =
                                item[
                                    'veiculo'];

                            final veiculo =
                                veiculoRaw
                                        is Map
                                    ? Map<String,
                                            dynamic>.from(
                                        veiculoRaw,
                                      )
                                    : <String,
                                        dynamic>{};

                            final motoristaRaw =
                                item[
                                    'motorista'];

                            final motorista =
                                motoristaRaw
                                        is Map
                                    ? Map<String,
                                            dynamic>.from(
                                        motoristaRaw,
                                      )
                                    : null;

                            final status =
                                item['status']
                                        ?.toString() ??
                                    '';

                            final corStatus =
                                _corStatus(
                              status,
                            );

                            final valor =
                                double.tryParse(
                                      item['valor_estimado']
                                          .toString(),
                                    ) ??
                                    0;

                            return Container(
                              padding:
                                  const EdgeInsets
                                      .all(
                                16,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    cinzaFundo,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  16,
                                ),
                              ),
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child:
                                            Text(
                                          item['tipo_reboque']
                                                  ?.toString() ??
                                              'Resgate',
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                16,
                                            fontWeight:
                                                FontWeight
                                                    .w700,
                                            color:
                                                pretoPrincipal,
                                          ),
                                        ),
                                      ),

                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal:
                                              9,
                                          vertical:
                                              5,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color:
                                              corStatus.withValues(
                                            alpha:
                                                0.1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child:
                                            Text(
                                          _nomeStatus(
                                            status,
                                          ),
                                          style:
                                              TextStyle(
                                            fontSize:
                                                10,
                                            fontWeight:
                                                FontWeight
                                                    .w700,
                                            color:
                                                corStatus,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                    height:
                                        12,
                                  ),

                                  Row(
                                    children: [
                                      const Icon(
                                        Icons
                                            .directions_car_outlined,
                                        size:
                                            16,
                                        color:
                                            cinzaTexto,
                                      ),

                                      const SizedBox(
                                        width:
                                            6,
                                      ),

                                      Expanded(
                                        child:
                                            Text(
                                          '${veiculo['marca'] ?? ''} '
                                          '${veiculo['modelo'] ?? ''} '
                                          '• ${veiculo['placa'] ?? ''}',
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                13,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                    height:
                                        10,
                                  ),

                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      const Icon(
                                        Icons
                                            .location_on_outlined,
                                        size:
                                            16,
                                        color:
                                            cinzaTexto,
                                      ),

                                      const SizedBox(
                                        width:
                                            6,
                                      ),

                                      Expanded(
                                        child:
                                            Text(
                                          item['endereco']
                                                  ?.toString() ??
                                              '',
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                12,
                                            color:
                                                cinzaTexto,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (motorista !=
                                      null) ...[
                                    const SizedBox(
                                      height:
                                          10,
                                    ),

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons
                                              .person_outline_rounded,
                                          size:
                                              16,
                                          color:
                                              cinzaTexto,
                                        ),

                                        const SizedBox(
                                          width:
                                              6,
                                        ),

                                        Expanded(
                                          child:
                                              Text(
                                            motorista['nome']
                                                    ?.toString() ??
                                                'Motorista',
                                            style:
                                                const TextStyle(
                                              fontSize:
                                                  12,
                                              color:
                                                  cinzaTexto,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  const SizedBox(
                                    height:
                                        14,
                                  ),

                                  const Divider(),

                                  const SizedBox(
                                    height:
                                        8,
                                  ),

                                  Row(
                                    children: [
                                      Expanded(
                                        child:
                                            Text(
                                          _formatarData(
                                            item['created_at']
                                                    ?.toString() ??
                                                '',
                                          ),
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                11,
                                            color:
                                                cinzaTexto,
                                          ),
                                        ),
                                      ),

                                      Text(
                                        'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
                                        style:
                                            const TextStyle(
                                          fontSize:
                                              15,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                          color:
                                              azulPrincipal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}