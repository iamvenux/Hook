import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'enderecos_store.dart';
import 'overlay_endereco.dart';
import 'salvar_endereco_dialog.dart';

class EnderecosSalvosScreen extends StatefulWidget {
  const EnderecosSalvosScreen({super.key});

  @override
  State<EnderecosSalvosScreen> createState() =>
      _EnderecosSalvosScreenState();
}

class _EnderecosSalvosScreenState extends State<EnderecosSalvosScreen> {
  bool _carregando = true;
  List<EnderecoSalvo> _salvos = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final lista = await EnderecosStore.listarSalvos();

    // Casa e Trabalho primeiro, depois os demais por nome.
    lista.sort((a, b) {
      int peso(String t) => t == 'casa' ? 0 : (t == 'trabalho' ? 1 : 2);

      final c = peso(a.tipo).compareTo(peso(b.tipo));

      return c != 0
          ? c
          : a.apelido.toLowerCase().compareTo(b.apelido.toLowerCase());
    });

    if (!mounted) return;

    setState(() {
      _salvos = lista;
      _carregando = false;
    });
  }

  EnderecoSalvo? _doTipo(String tipo) {
    for (final e in _salvos) {
      if (e.tipo == tipo) return e;
    }
    return null;
  }

  Future<void> _adicionar({String? tipoInicial}) async {
    final r = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EnderecoOverlay(
          enderecoAtual: '',
          titulo: tipoInicial == 'casa'
              ? 'Endereço de casa'
              : tipoInicial == 'trabalho'
                  ? 'Endereço do trabalho'
                  : 'Novo endereço',
          textoConfirmar: 'Usar este endereço',
          modoCadastro: true,
        ),
      ),
    );

    if (r == null || !mounted) return;

    final salvo = await mostrarSalvarEndereco(
      context,
      endereco: r['endereco'] as String,
      lat: r['lat'] as double,
      lng: r['lng'] as double,
      tipoInicial: tipoInicial,
    );

    if (salvo == null) return;

    await EnderecosStore.salvar(salvo);
    await _carregar();

    _aviso('"${salvo.apelido}" salvo.');
  }

  Future<void> _editar(EnderecoSalvo e) async {
    final salvo = await mostrarSalvarEndereco(
      context,
      endereco: e.endereco,
      lat: e.lat,
      lng: e.lng,
      existente: e,
    );

    if (salvo == null) return;

    await EnderecosStore.salvar(salvo);
    await _carregar();

    _aviso('Endereço atualizado.');
  }

  Future<void> _trocarLocal(EnderecoSalvo e) async {
    final r = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EnderecoOverlay(
          // enderecoAtual vazio: não oferece "usar minha localização";
          // a coordenada só posiciona o pin inicial do mapa.
          enderecoAtual: '',
          coordenadaAtual: LatLng(e.lat, e.lng),
          titulo: 'Alterar "${e.apelido}"',
          textoConfirmar: 'Usar este endereço',
          modoCadastro: true,
        ),
      ),
    );

    if (r == null) return;

    await EnderecosStore.salvar(
      EnderecoSalvo(
        id: e.id,
        apelido: e.apelido,
        tipo: e.tipo,
        endereco: r['endereco'] as String,
        lat: r['lat'] as double,
        lng: r['lng'] as double,
      ),
    );

    await _carregar();

    _aviso('Endereço atualizado.');
  }

  Future<void> _excluir(EnderecoSalvo e) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir endereço?'),
        content: Text('"${e.apelido}" será removido dos seus endereços salvos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await EnderecosStore.remover(e.id);
    await _carregar();

    _aviso('Endereço removido.');
  }

  void _aviso(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: pretoPrincipal),
        title: const Text(
          'Endereços salvos',
          style: TextStyle(
            color: pretoPrincipal,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: azulPrincipal),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const Text(
                  'Guarde os lugares que você mais usa e escolha-os '
                  'rapidinho na hora de pedir ajuda.',
                  style: TextStyle(fontSize: 14, color: cinzaTexto),
                ),
                const SizedBox(height: 18),
                _atalho(
                  tipo: 'casa',
                  rotuloVazio: 'Adicionar casa',
                ),
                const SizedBox(height: 10),
                _atalho(
                  tipo: 'trabalho',
                  rotuloVazio: 'Adicionar trabalho',
                ),
                const SizedBox(height: 22),
                const Text(
                  'OUTROS ENDEREÇOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cinzaTexto,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                if (_salvos.where((e) => e.tipo == 'outro').isEmpty)
                  _vazioOutros()
                else
                  for (final e in _salvos.where((e) => e.tipo == 'outro'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _cartao(e),
                    ),
                if (_salvos.where((e) => e.tipo == 'outro').isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _adicionar(),
                      icon: const Icon(Icons.add_location_alt_rounded,
                          size: 18),
                      label: const Text(
                        'Adicionar endereço',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: azulPrincipal,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _atalho({
    required String tipo,
    required String rotuloVazio,
  }) {
    final existente = _doTipo(tipo);

    if (existente != null) return _cartao(existente);

    return InkWell(
      onTap: () => _adicionar(tipoInicial: tipo),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cinzaFundo,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconeDoTipo(tipo), color: cinzaTexto, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                rotuloVazio,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: pretoPrincipal,
                ),
              ),
            ),
            const Icon(Icons.add_rounded, color: azulPrincipal),
          ],
        ),
      ),
    );
  }

  Widget _vazioOutros() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: cinzaFundo,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.bookmark_border_rounded,
              size: 40, color: cinzaTexto),
          const SizedBox(height: 10),
          const Text(
            'Nenhum endereço extra salvo',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: pretoPrincipal,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Salve a casa de um parente, a academia, a faculdade...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cinzaTexto),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _adicionar(),
            icon: const Icon(Icons.add_location_alt_rounded, size: 18),
            label: const Text('Adicionar endereço'),
            style: ElevatedButton.styleFrom(
              backgroundColor: azulPrincipal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartao(EnderecoSalvo e) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: azulPrincipal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconeDoTipo(e.tipo),
                color: azulPrincipal, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.apelido,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: pretoPrincipal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  e.endereco,
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: cinzaTexto),
            onSelected: (acao) {
              switch (acao) {
                case 'nome':
                  _editar(e);
                  break;
                case 'local':
                  _trocarLocal(e);
                  break;
                case 'excluir':
                  _excluir(e);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'nome', child: Text('Editar nome')),
              PopupMenuItem(
                  value: 'local', child: Text('Alterar localização')),
              PopupMenuItem(
                value: 'excluir',
                child: Text(
                  'Excluir',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
