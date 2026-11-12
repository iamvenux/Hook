import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_application_1/controllers/endereco_controller.dart';
import 'package:flutter_application_1/models/api_exception.dart';
import 'package:flutter_application_1/models/endereco_salvo.dart';
import 'package:flutter_application_1/widgets/endereco_overlay.dart';

/// Lista de endereços salvos do cliente, com adicionar e excluir.
///
/// Com [selecionar] = true (aberta pela home), tocar num endereço
/// fecha a tela devolvendo o [EnderecoSalvo] escolhido.
class EnderecosSalvosScreen extends StatefulWidget {
  final bool selecionar;

  /// Onde o mapa abre ao adicionar um endereço (ex.: posição atual).
  final LatLng? coordenadaInicial;

  const EnderecosSalvosScreen({
    super.key,
    this.selecionar = false,
    this.coordenadaInicial,
  });

  @override
  State<EnderecosSalvosScreen> createState() => _EnderecosSalvosScreenState();
}

class _EnderecosSalvosScreenState extends State<EnderecosSalvosScreen> {
  static const Color azulPrincipal = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto = Color(0xFF8A8A8A);
  static const Color cinzaFundo = Color(0xFFF5F5F5);

  final EnderecoController _controller = EnderecoController.instance;

  List<EnderecoSalvo> _enderecos = [];

  bool _carregando = true;
  bool _salvando = false;

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
      final lista = await _controller.listar();

      if (!mounted) return;

      setState(() {
        _enderecos = lista;
        _carregando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(e.mensagem);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem('Não foi possível carregar os endereços.');
    }
  }

  // ============================================================
  // ADICIONAR
  // ============================================================

  Future<void> _adicionar() async {
    if (_salvando) return;

    // Reaproveita o overlay da home para escolher o ponto no mapa.
    final resultado = await showGeneralDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => EnderecoOverlay(
        enderecoAtual: '',
        coordenadaAtual: widget.coordenadaInicial,
      ),
    );

    if (resultado is! Map || !mounted) return;

    final endereco = (resultado['endereco'] as String?)?.trim() ?? '';
    final lat = (resultado['lat'] as num?)?.toDouble();
    final lng = (resultado['lng'] as num?)?.toDouble();

    if (endereco.isEmpty ||
        endereco == 'Endereço não encontrado' ||
        endereco == 'Buscando endereço...' ||
        lat == null ||
        lng == null) {
      _mostrarMensagem('Toque no mapa ou digite um endereço válido.');
      return;
    }

    final apelido = await _pedirApelido();

    if (apelido == null || !mounted) return;

    setState(() {
      _salvando = true;
    });

    try {
      await _controller.adicionar(
        apelido: apelido,
        endereco: endereco,
        latitude: lat,
        longitude: lng,
      );

      if (!mounted) return;

      _mostrarMensagem('Endereço salvo.');

      await _carregar();
    } on ApiException catch (e) {
      if (!mounted) return;
      _mostrarMensagem(e.mensagem);
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível salvar o endereço.');
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  /// Pergunta como o endereço vai se chamar (Casa, Trabalho...).
  Future<String?> _pedirApelido() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Nome do endereço',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: pretoPrincipal,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ex.: Casa, Trabalho, Faculdade',
                style: TextStyle(fontSize: 13, color: cinzaTexto),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Casa',
                  filled: true,
                  fillColor: cinzaFundo,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (valor) {
                  if (valor.trim().isNotEmpty) {
                    Navigator.of(dialogContext).pop(valor.trim());
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: cinzaTexto),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final valor = controller.text.trim();
                if (valor.isEmpty) return;
                Navigator.of(dialogContext).pop(valor);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: azulPrincipal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EXCLUIR
  // ============================================================

  Future<void> _excluir(EnderecoSalvo endereco) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Excluir endereço?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: pretoPrincipal,
            ),
          ),
          content: Text(
            '"${endereco.apelido}" será removido da sua lista.',
            style: const TextStyle(fontSize: 14, color: cinzaTexto),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: cinzaTexto),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Excluir',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    try {
      await _controller.excluir(endereco.id);

      if (!mounted) return;

      setState(() {
        _enderecos.removeWhere((e) => e.id == endereco.id);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      _mostrarMensagem(e.mensagem);
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível excluir o endereço.');
    }
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: pretoPrincipal),
        ),
        title: Text(
          widget.selecionar ? 'Escolher endereço' : 'Endereços salvos',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: pretoPrincipal,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(child: _buildLista()),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _adicionar,
                icon: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.add_location_alt_outlined),
                label: const Text(
                  'Adicionar endereço',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulPrincipal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      azulPrincipal.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: azulPrincipal),
      );
    }

    if (_enderecos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: azulPrincipal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: azulPrincipal,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum endereço salvo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: pretoPrincipal,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Salve lugares que você usa sempre\npara pedir socorro mais rápido.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: cinzaTexto),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: azulPrincipal,
      onRefresh: _carregar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        itemCount: _enderecos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final endereco = _enderecos[index];

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.selecionar
                  ? () => Navigator.of(context).pop(endereco)
                  : null,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: azulPrincipal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: azulPrincipal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            endereco.apelido,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: pretoPrincipal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            endereco.endereco,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: cinzaTexto,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.selecionar)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: cinzaTexto,
                      )
                    else
                      IconButton(
                        onPressed: () => _excluir(endereco),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                        ),
                        tooltip: 'Excluir',
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
