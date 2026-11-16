import 'dart:async';

import 'package:flutter/material.dart';

import 'api_service.dart';

class ChatSolicitacaoScreen extends StatefulWidget {
  final int solicitacaoId;
  final String titulo;

  /// true = quem está no chat é o motorista (muda as respostas prontas).
  final bool motorista;

  const ChatSolicitacaoScreen({
    super.key,
    required this.solicitacaoId,
    required this.titulo,
    this.motorista = false,
  });

  @override
  State<ChatSolicitacaoScreen> createState() =>
      _ChatSolicitacaoScreenState();
}

class _ChatSolicitacaoScreenState
    extends State<ChatSolicitacaoScreen> {
  static const Color azulPrincipal =
      Color(0xFF1A7EF5);

  final _controller =
      TextEditingController();

  final _scrollController =
      ScrollController();

  Timer? _timer;

  List<Map<String, dynamic>>
      _mensagens = [];

  bool _carregando = true;
  bool _enviando = false;
  bool _consultando = false;

  @override
  void initState() {
    super.initState();

    _carregar();

    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _carregar(
        silencioso: true,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _carregar({
    bool silencioso = false,
  }) async {
    if (_consultando) return;

    _consultando = true;

    try {
      final lista =
          await ApiService.instance
              .listarMensagens(
        widget.solicitacaoId,
      );

      if (!mounted) return;

      final mudou =
          lista.length !=
              _mensagens.length;

      setState(() {
        _mensagens = lista;

        if (!silencioso) {
          _carregando = false;
        }
      });

      if (mudou) {
        WidgetsBinding.instance
            .addPostFrameCallback(
          (_) => _rolarFim(),
        );
      }
    } catch (_) {
      if (!mounted) return;

      if (!silencioso) {
        setState(() {
          _carregando = false;
        });
      }
    } finally {
      _consultando = false;
    }
  }

  static const List<String> _prontasMotorista = [
    'Estou a caminho',
    'Estou chegando',
    'Cheguei ao local',
    'Pode me mandar um ponto de referência?',
    'Estou com dificuldade de achar o local',
    'Atendimento concluído. Obrigado!',
  ];

  static const List<String> _prontasCliente = [
    'Estou no local',
    'Estou te esperando',
    'Quanto tempo falta?',
    'Estou na entrada principal',
    'O veículo está na rua',
    'Obrigado!',
  ];

  Future<void> _enviar([String? pronta]) async {
    final texto =
        (pronta ?? _controller.text).trim();

    if (texto.isEmpty ||
        _enviando) {
      return;
    }

    setState(() {
      _enviando = true;
    });

    try {
      await ApiService.instance
          .enviarMensagem(
        solicitacaoId:
            widget.solicitacaoId,
        mensagem: texto,
      );

      if (pronta == null) _controller.clear();

      await _carregar();

      _rolarFim();
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.mensagem,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  /// "2026-11-14 09:50:12" -> "09:50"
  String _hora(String? bruto) {
    if (bruto == null) return '';

    final m = RegExp(r'(\d{2}):(\d{2})').firstMatch(bruto);

    return m == null ? '' : '${m.group(1)}:${m.group(2)}';
  }

  void _rolarFim() {
    if (!_scrollController
        .hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController
          .position.maxScrollExtent,
      duration:
          const Duration(
        milliseconds: 250,
      ),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final meuId =
        ApiService.instance.usuarioId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF1A1A1A),
        ),
        title: Text(
          widget.titulo,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFEEEEEE),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _carregando
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : _mensagens.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Nenhuma mensagem ainda.\n'
                            'Escreva abaixo para combinar os detalhes '
                            'do atendimento.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Color(0xFF8A8A8A),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller:
                            _scrollController,
                        padding:
                            const EdgeInsets
                                .all(16),
                        itemCount:
                            _mensagens.length,
                        itemBuilder:
                            (context, index) {
                          final item =
                              _mensagens[index];

                          final remetenteId =
                              int.tryParse(
                            item['remetente_id']
                                .toString(),
                          );

                          final minha =
                              remetenteId ==
                                  meuId;

                          return Align(
                            alignment: minha
                                ? Alignment
                                    .centerRight
                                : Alignment
                                    .centerLeft,
                            child: Container(
                              constraints:
                                  BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(
                                          context,
                                        )
                                        .size
                                        .width *
                                    0.75,
                              ),
                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom: 10,
                              ),
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: minha
                                    ? azulPrincipal
                                    : const Color(
                                        0xFFF0F0F0,
                                      ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  14,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    item['mensagem']
                                            ?.toString() ??
                                        '',
                                    style:
                                        TextStyle(
                                      color: minha
                                          ? Colors
                                              .white
                                          : Colors
                                              .black87,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    _hora(
                                      item['created_at']
                                          ?.toString(),
                                    ),
                                    style:
                                        TextStyle(
                                      fontSize: 10,
                                      color: minha
                                          ? Colors
                                              .white70
                                          : Colors
                                              .black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            height: 48,
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              itemCount: (widget.motorista
                      ? _prontasMotorista
                      : _prontasCliente)
                  .length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final frase = (widget.motorista
                    ? _prontasMotorista
                    : _prontasCliente)[i];

                return ActionChip(
                  label: Text(
                    frase,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: azulPrincipal,
                    ),
                  ),
                  backgroundColor: const Color(0xFFE8F2FE),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  onPressed: _enviando ? null : () => _enviar(frase),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                12,
                8,
                12,
                12,
              ),
              decoration:
                  const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black12,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                          _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction:
                          TextInputAction
                              .send,
                      onSubmitted:
                          (_) => _enviar(),
                      decoration:
                          InputDecoration(
                        hintText:
                            'Digite uma mensagem...',
                        filled: true,
                        fillColor:
                            const Color(
                          0xFFF5F5F5,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            24,
                          ),
                          borderSide:
                              BorderSide
                                  .none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  IconButton.filled(
                    onPressed:
                        _enviando
                            ? null
                            : () => _enviar(),
                    icon: _enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color: Colors
                                  .white,
                            ),
                          )
                        : const Icon(
                            Icons
                                .send_rounded,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
