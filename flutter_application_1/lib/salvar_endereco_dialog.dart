import 'package:flutter/material.dart';

import 'enderecos_store.dart';

const Color _azul = Color(0xFF1A7EF5);
const Color _preto = Color(0xFF1A1A1A);
const Color _cinzaTexto = Color(0xFF8A8A8A);
const Color _cinzaFundo = Color(0xFFF5F5F5);

IconData iconeDoTipo(String tipo) {
  switch (tipo) {
    case 'casa':
      return Icons.home_rounded;
    case 'trabalho':
      return Icons.work_rounded;
    default:
      return Icons.bookmark_rounded;
  }
}

/// Abre a folha para dar apelido e escolher o tipo do endereço.
/// Retorna o [EnderecoSalvo] pronto (ainda não gravado) ou null se cancelar.
Future<EnderecoSalvo?> mostrarSalvarEndereco(
  BuildContext context, {
  required String endereco,
  required double lat,
  required double lng,
  EnderecoSalvo? existente,
  String? tipoInicial,
}) {
  return showModalBottomSheet<EnderecoSalvo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SalvarEnderecoSheet(
      endereco: endereco,
      lat: lat,
      lng: lng,
      existente: existente,
      tipoInicial: tipoInicial,
    ),
  );
}

class _SalvarEnderecoSheet extends StatefulWidget {
  final String endereco;
  final double lat;
  final double lng;
  final EnderecoSalvo? existente;
  final String? tipoInicial;

  const _SalvarEnderecoSheet({
    required this.endereco,
    required this.lat,
    required this.lng,
    this.existente,
    this.tipoInicial,
  });

  @override
  State<_SalvarEnderecoSheet> createState() => _SalvarEnderecoSheetState();
}

class _SalvarEnderecoSheetState extends State<_SalvarEnderecoSheet> {
  static const _tipos = {
    'casa': 'Casa',
    'trabalho': 'Trabalho',
    'outro': 'Outro',
  };

  late String _tipo;
  late final TextEditingController _apelido;
  String? _erro;

  @override
  void initState() {
    super.initState();

    _tipo = widget.existente?.tipo ?? widget.tipoInicial ?? 'outro';

    _apelido = TextEditingController(
      text: widget.existente?.apelido ??
          (_tipo == 'outro' ? '' : _tipos[_tipo]),
    );
  }

  @override
  void dispose() {
    _apelido.dispose();
    super.dispose();
  }

  void _trocarTipo(String novo) {
    final textoAtual = _apelido.text.trim();
    final eraPadrao = textoAtual.isEmpty ||
        _tipos.values.contains(textoAtual);

    setState(() {
      _tipo = novo;

      if (eraPadrao) {
        _apelido.text = novo == 'outro' ? '' : _tipos[novo]!;
      }
    });
  }

  void _salvar() {
    final apelido = _apelido.text.trim();

    if (apelido.isEmpty) {
      setState(() => _erro = 'Dê um nome para este endereço.');
      return;
    }

    Navigator.pop(
      context,
      EnderecoSalvo(
        id: widget.existente?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        apelido: apelido,
        tipo: _tipo,
        endereco: widget.endereco,
        lat: widget.lat,
        lng: widget.lng,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.existente == null
                  ? 'Salvar endereço'
                  : 'Editar endereço salvo',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _preto,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cinzaFundo,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: _azul, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.endereco,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _preto,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              children: _tipos.entries.map((e) {
                final ativo = _tipo == e.key;

                return ChoiceChip(
                  avatar: Icon(
                    iconeDoTipo(e.key),
                    size: 18,
                    color: ativo ? Colors.white : _cinzaTexto,
                  ),
                  label: Text(e.value),
                  selected: ativo,
                  showCheckmark: false,
                  selectedColor: _azul,
                  backgroundColor: _cinzaFundo,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ativo ? Colors.white : _preto,
                  ),
                  onSelected: (_) => _trocarTipo(e.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _apelido,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 30,
              decoration: InputDecoration(
                hintText: 'Ex.: Casa da mãe, Academia',
                errorText: _erro,
                filled: true,
                fillColor: _cinzaFundo,
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) {
                if (_erro != null) setState(() => _erro = null);
              },
              onSubmitted: (_) => _salvar(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _azul,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Salvar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
