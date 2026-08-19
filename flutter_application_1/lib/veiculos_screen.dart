import 'package:flutter/material.dart';

import 'api_service.dart';
import 'adicionar_veiculo_screen.dart';

class VeiculosScreen extends StatefulWidget {
  const VeiculosScreen({
    super.key,
  });

  @override
  State<VeiculosScreen> createState() =>
      _VeiculosScreenState();
}

class _VeiculosScreenState
    extends State<VeiculosScreen> {
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
      _veiculos = [];

  @override
  void initState() {
    super.initState();

    _carregarVeiculos();
  }

  Future<void> _carregarVeiculos() async {
    if (mounted) {
      setState(() {
        _carregando = true;
      });
    }

    try {
      final lista =
          await ApiService.instance
              .listarVeiculos();

      if (!mounted) return;

      setState(() {
        _veiculos = lista;
        _carregando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        e.mensagem,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        'Não foi possível carregar seus veículos.',
      );
    }
  }

  Future<void> _adicionarVeiculo() async {
    final resultado =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AdicionarVeiculoScreen(),
      ),
    );

    if (resultado == true) {
      await _carregarVeiculos();
    }
  }

  Future<void> _definirPadrao(
    Map<String, dynamic> veiculo,
  ) async {
    final id = int.tryParse(
      veiculo['id'].toString(),
    );

    if (id == null) return;

    try {
      final resposta =
          await ApiService.instance
              .definirVeiculoPadrao(id);

      if (!mounted) return;

      _mostrarMensagem(
        resposta['mensagem']
                ?.toString() ??
            'Veículo padrão atualizado.',
      );

      await _carregarVeiculos();
    } on ApiException catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        e.mensagem,
      );
    }
  }

  Future<void> _editarVeiculo(
    Map<String, dynamic> veiculo,
  ) async {
    final marcaController =
        TextEditingController(
      text: veiculo['marca']
          ?.toString(),
    );

    final modeloController =
        TextEditingController(
      text: veiculo['modelo']
          ?.toString(),
    );

    final anoController =
        TextEditingController(
      text: veiculo['ano']
          ?.toString(),
    );

    final placaController =
        TextEditingController(
      text: veiculo['placa']
          ?.toString(),
    );

    final corController =
        TextEditingController(
      text: veiculo['cor']
          ?.toString(),
    );

    String tipo =
        veiculo['tipo']
                ?.toString() ??
            'Carro';

    final resultado =
        await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setModalState,
          ) {
            return Padding(
              padding:
                  EdgeInsets.fromLTRB(
                24,
                22,
                24,
                MediaQuery.of(context)
                        .viewInsets
                        .bottom +
                    24,
              ),
              child:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.grey[
                                  300],
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    const Text(
                      'Editar veículo',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight
                                .bold,
                        color:
                            pretoPrincipal,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    DropdownButtonFormField<
                        String>(
                      initialValue: tipo,
                      decoration:
                          _inputDecoration(
                        'Tipo de veículo',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Carro',
                          child: Text(
                            'Carro',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Moto',
                          child: Text(
                            'Moto',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'SUV',
                          child: Text(
                            'SUV',
                          ),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor ==
                            null) {
                          return;
                        }

                        setModalState(
                          () {
                            tipo = valor;
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          marcaController,
                      decoration:
                          _inputDecoration(
                        'Marca',
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          modeloController,
                      decoration:
                          _inputDecoration(
                        'Modelo',
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          anoController,
                      keyboardType:
                          TextInputType
                              .number,
                      decoration:
                          _inputDecoration(
                        'Ano',
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          placaController,
                      decoration:
                          _inputDecoration(
                        'Placa',
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          corController,
                      decoration:
                          _inputDecoration(
                        'Cor',
                      ),
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 52,
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
                              pretoPrincipal,
                          foregroundColor:
                              Colors.white,
                        ),
                        child:
                            const Text(
                          'Salvar alterações',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (resultado != true) {
      return;
    }

    final ano = int.tryParse(
      anoController.text.trim(),
    );

    if (ano == null) {
      _mostrarMensagem(
        'Informe um ano válido.',
      );

      return;
    }

    try {
      final resposta =
          await ApiService.instance
              .editarVeiculo(
        veiculoId: int.parse(
          veiculo['id'].toString(),
        ),
        tipo: tipo,
        marca:
            marcaController.text.trim(),
        modelo:
            modeloController.text.trim(),
        ano: ano,
        placa:
            placaController.text.trim(),
        cor:
            corController.text.trim(),
      );

      if (!mounted) return;

      _mostrarMensagem(
        resposta['mensagem']
                ?.toString() ??
            'Veículo atualizado.',
      );

      await _carregarVeiculos();
    } on ApiException catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        e.mensagem,
      );
    }
  }

  // ============================================================
  // EXCLUIR VEÍCULO
  // ============================================================

  Future<void> _confirmarExclusao(
    Map<String, dynamic> veiculo,
  ) async {
    final nome =
        '${veiculo['marca'] ?? ''} ${veiculo['modelo'] ?? ''}'
            .trim();

    final confirmar =
        await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            36,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFE0E0E0),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 26,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Excluir veículo?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: pretoPrincipal,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Tem certeza que deseja excluir '
                '${nome.isEmpty ? 'este veículo' : nome}?',
                style: const TextStyle(
                  fontSize: 14,
                  color: cinzaTexto,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Esta ação não poderá ser desfeita.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 26),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            pretoPrincipal,
                        side: const BorderSide(
                          color:
                              Color(0xFFDDDDDD),
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          true,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.red,
                        foregroundColor:
                            Colors.white,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Excluir',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    final veiculoId = int.tryParse(
      veiculo['id'].toString(),
    );

    if (veiculoId == null) {
      return;
    }

    try {
      final resposta =
          await ApiService.instance
              .excluirVeiculo(
        veiculoId,
      );

      if (!mounted) return;

      _mostrarMensagem(
        resposta['mensagem']
                ?.toString() ??
            'Veículo excluído.',
      );

      await _carregarVeiculos();
    } on ApiException catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        e.mensagem,
      );
    } catch (_) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível excluir o veículo.',
      );
    }
  }

  void _mostrarMensagem(
    String mensagem,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  static InputDecoration
      _inputDecoration(
    String label,
  ) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: cinzaFundo,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            BorderSide.none,
      ),
    );
  }

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

      default:
        return Icons
            .directions_car_rounded;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets
                    .fromLTRB(
              24,
              28,
              24,
              18,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Meus veículos',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color:
                              pretoPrincipal,
                        ),
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Text(
                        'Gerencie seus veículos cadastrados',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              cinzaTexto,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed:
                      _adicionarVeiculo,
                  style:
                      IconButton.styleFrom(
                    backgroundColor:
                        azulPrincipal,
                    foregroundColor:
                        Colors.white,
                  ),
                  icon:
                      const Icon(
                    Icons.add_rounded,
                  ),
                ),
              ],
            ),
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
                : _veiculos.isEmpty
                    ? _buildVazio()
                    : RefreshIndicator(
                        onRefresh:
                            _carregarVeiculos,
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
                              _veiculos
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
                            final v =
                                _veiculos[
                                    index];

                            final padrao =
                                v['padrao']
                                        .toString() ==
                                    '1';

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
                                border:
                                    Border.all(
                                  color: padrao
                                      ? azulPrincipal
                                      : Colors
                                          .transparent,
                                  width:
                                      1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width:
                                        52,
                                    height:
                                        52,
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          Colors.white,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        14,
                                      ),
                                    ),
                                    child:
                                        Icon(
                                      _iconeVeiculo(
                                        v['tipo']
                                            ?.toString(),
                                      ),
                                      color:
                                          azulPrincipal,
                                    ),
                                  ),

                                  const SizedBox(
                                    width:
                                        14,
                                  ),

                                  Expanded(
                                    child:
                                        Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          '${v['marca'] ?? ''} ${v['modelo'] ?? ''}',
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

                                        const SizedBox(
                                          height:
                                              3,
                                        ),

                                        Text(
                                          '${v['placa'] ?? ''} • ${v['cor'] ?? ''} • ${v['ano'] ?? ''}',
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                12,
                                            color:
                                                cinzaTexto,
                                          ),
                                        ),

                                        if (padrao) ...[
                                          const SizedBox(
                                            height:
                                                6,
                                          ),
                                          Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                              horizontal:
                                                  8,
                                              vertical:
                                                  3,
                                            ),
                                            decoration:
                                                BoxDecoration(
                                              color:
                                                  azulPrincipal.withValues(
                                                alpha:
                                                    0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                20,
                                              ),
                                            ),
                                            child:
                                                const Text(
                                              'PADRÃO',
                                              style:
                                                  TextStyle(
                                                color:
                                                    azulPrincipal,
                                                fontSize:
                                                    9,
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  PopupMenuButton<
                                      String>(
                                    onSelected:
                                        (valor) {
                                      if (valor ==
                                          'editar') {
                                        _editarVeiculo(
                                          v,
                                        );
                                      }

                                      if (valor ==
                                          'padrao') {
                                        _definirPadrao(
                                          v,
                                        );
                                      }

                                      if (valor ==
                                          'excluir') {
                                        _confirmarExclusao(
                                          v,
                                        );
                                      }
                                    },
                                    itemBuilder:
                                        (_) => [
                                      const PopupMenuItem(
                                        value:
                                            'editar',
                                        child:
                                            Row(
                                          children: [
                                            Icon(
                                              Icons
                                                  .edit_outlined,
                                            ),
                                            SizedBox(
                                              width:
                                                  8,
                                            ),
                                            Text(
                                              'Editar',
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (!padrao)
                                        const PopupMenuItem(
                                          value:
                                              'padrao',
                                          child:
                                              Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .star_outline_rounded,
                                              ),
                                              SizedBox(
                                                width:
                                                    8,
                                              ),
                                              Text(
                                                'Definir como padrão',
                                              ),
                                            ],
                                          ),
                                        ),

                                      const PopupMenuDivider(),

                                      const PopupMenuItem(
                                        value:
                                            'excluir',
                                        child:
                                            Row(
                                          children: [
                                            Icon(
                                              Icons
                                                  .delete_outline_rounded,
                                              color:
                                                  Colors.red,
                                            ),
                                            SizedBox(
                                              width:
                                                  8,
                                            ),
                                            Text(
                                              'Excluir veículo',
                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors.red,
                                              ),
                                            ),
                                          ],
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

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          const Icon(
            Icons
                .directions_car_outlined,
            size: 54,
            color:
                cinzaTexto,
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'Nenhum veículo cadastrado',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          ElevatedButton.icon(
            onPressed:
                _adicionarVeiculo,
            icon:
                const Icon(
              Icons.add_rounded,
            ),
            label:
                const Text(
              'Adicionar veículo',
            ),
          ),
        ],
      ),
    );
  }
}