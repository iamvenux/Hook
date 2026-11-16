import 'package:flutter/material.dart';

import 'api_service.dart';
import 'perfil_componentes.dart';

const Color _azul = Color(0xFF1A7EF5);
const Color _preto = Color(0xFF1A1A1A);
const Color _cinza = Color(0xFF8A8A8A);
const Color _cinzaFundo = Color(0xFFF5F5F5);
const Color _amarelo = Color(0xFFFFB400);

/// Tela de avaliação do atendimento. Serve para o cliente avaliar o
/// motorista e para o motorista avaliar o cliente.
///
/// Fecha devolvendo `true` quando a avaliação foi enviada.
class AvaliacaoScreen extends StatefulWidget {
  final int solicitacaoId;
  final String nomeAvaliado;
  final String? fotoAvaliado;

  /// true = quem avalia é o motorista (muda os textos).
  final bool avaliadorMotorista;

  const AvaliacaoScreen({
    super.key,
    required this.solicitacaoId,
    required this.nomeAvaliado,
    this.fotoAvaliado,
    this.avaliadorMotorista = false,
  });

  @override
  State<AvaliacaoScreen> createState() => _AvaliacaoScreenState();
}

class _AvaliacaoScreenState extends State<AvaliacaoScreen> {
  final _comentarioController = TextEditingController();

  int _nota = 0;
  bool _enviando = false;

  static const _rotulos = [
    '',
    'Muito ruim',
    'Ruim',
    'Regular',
    'Bom',
    'Excelente!',
  ];

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  String get _primeiroNome {
    final n = widget.nomeAvaliado.trim();

    return n.isEmpty ? '' : n.split(' ').first;
  }

  Future<void> _enviar() async {
    if (_nota == 0 || _enviando) return;

    setState(() => _enviando = true);

    try {
      await ApiService.instance.avaliarSolicitacao(
        solicitacaoId: widget.solicitacaoId,
        nota: _nota,
        comentario: _comentarioController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação enviada. Obrigado!')),
      );

      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() => _enviando = false);

      // "Você já avaliou" não é erro para a pessoa: só fecha.
      final jaAvaliou = e.mensagem.toLowerCase().contains('já avaliou');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem)),
      );

      if (jaAvaliou) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() => _enviando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível enviar agora. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final papel = widget.avaliadorMotorista ? 'o cliente' : 'o motorista';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
            child: const Text(
              'Agora não',
              style: TextStyle(color: _cinza, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              AvatarUsuario(
                nome: widget.nomeAvaliado,
                fotoUrl: widget.fotoAvaliado,
                tamanho: 96,
              ),
              const SizedBox(height: 18),
              const Text(
                'Atendimento concluído',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _azul,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _primeiroNome.isEmpty
                    ? 'Como foi o atendimento?'
                    : 'Como foi o atendimento com $_primeiroNome?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _preto,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sua avaliação ajuda a manter o Hook seguro e confiável para '
                '$papel e para quem vem depois.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: _cinza,
                ),
              ),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final ativa = i < _nota;

                  return GestureDetector(
                    onTap: _enviando ? null : () => setState(() => _nota = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedScale(
                        scale: ativa ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 140),
                        child: Icon(
                          ativa ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 48,
                          color: ativa ? _amarelo : const Color(0xFFCFCFCF),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 22,
                child: Text(
                  _rotulos[_nota],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _preto,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _comentarioController,
                enabled: !_enviando,
                maxLength: 300,
                maxLines: 4,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Quer deixar um comentário? (opcional)',
                  hintStyle: const TextStyle(color: _cinza),
                  filled: true,
                  fillColor: _cinzaFundo,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _azul, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _nota == 0 || _enviando ? null : _enviar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _preto,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFDDDDDD),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enviar avaliação',
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
      ),
    );
  }
}
