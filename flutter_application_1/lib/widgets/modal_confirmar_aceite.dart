import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/chamado_disponivel.dart';

// ============================================================
// MODAL DE CONFIRMAÇÃO
// ============================================================

class ModalConfirmarAceite
    extends StatelessWidget {
  final ChamadoDisponivel chamado;

  static const Color azulPrincipal =
      Color(0xFF1A7EF5);

  static const Color cinzaTexto =
      Color(0xFF8A8A8A);

  static const Color pretoPrincipal =
      Color(0xFF1A1A1A);

  const ModalConfirmarAceite({
    super.key,
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