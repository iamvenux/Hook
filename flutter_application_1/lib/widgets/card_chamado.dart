import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/chamado_disponivel.dart';

// ============================================================
// CARD DO CHAMADO
// ============================================================

class CardChamado
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

  const CardChamado({
    super.key,
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
