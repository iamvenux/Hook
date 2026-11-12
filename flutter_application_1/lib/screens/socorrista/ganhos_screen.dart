import 'package:flutter/material.dart';

import 'package:flutter_application_1/controllers/socorrista_controller.dart';
import 'package:flutter_application_1/models/api_exception.dart';
import 'package:flutter_application_1/models/resumo_ganhos.dart';

/// Ganhos do socorrista: totais e lista dos atendimentos concluídos.
///
/// Com [embutido] = true é usada dentro da aba "Histórico" da home
/// (sem AppBar); sem ele, abre como tela própria pelo perfil.
class GanhosScreen extends StatefulWidget {
  final bool embutido;

  const GanhosScreen({
    super.key,
    this.embutido = false,
  });

  @override
  State<GanhosScreen> createState() => _GanhosScreenState();
}

class _GanhosScreenState extends State<GanhosScreen> {
  static const Color azulPrincipal = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto = Color(0xFF8A8A8A);
  static const Color cinzaFundo = Color(0xFFF5F5F5);
  static const Color verde = Color(0xFF22C55E);

  ResumoGanhos? _resumo;

  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final resumo = await SocorristaController.instance.listarGanhos();

      if (!mounted) return;

      setState(() {
        _resumo = resumo;
        _carregando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = e.mensagem;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = 'Não foi possível carregar seus ganhos.';
      });
    }
  }

  static String formatarReais(double valor) {
    final inteiro = valor.floor();
    final centavos = ((valor - inteiro) * 100).round().toString().padLeft(2, '0');

    // Separador de milhar com ponto: 1.250
    final texto = inteiro.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < texto.length; i++) {
      final restante = texto.length - i;
      buffer.write(texto[i]);
      if (restante > 1 && restante % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'R\$ $buffer,$centavos';
  }

  String _formatarData(DateTime? data) {
    if (data == null) return '';

    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} às '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embutido) {
      return _buildCorpo();
    }

    return Scaffold(
      backgroundColor: cinzaFundo,
      appBar: AppBar(
        backgroundColor: cinzaFundo,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: pretoPrincipal),
        ),
        title: const Text(
          'Ganhos e repasses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: pretoPrincipal,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildCorpo(),
    );
  }

  Widget _buildCorpo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(color: azulPrincipal),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, color: cinzaTexto, size: 40),
              const SizedBox(height: 12),
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: cinzaTexto),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _carregar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final resumo = _resumo!;

    return RefreshIndicator(
      color: azulPrincipal,
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // ------------------------------------------------------
          // TOTAL GERAL
          // ------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E8FF7), Color(0xFF1565D8)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: azulPrincipal.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL RECEBIDO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatarReais(resumo.totalGeral),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  resumo.quantidade == 1
                      ? '1 atendimento concluído'
                      : '${resumo.quantidade} atendimentos concluídos',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ------------------------------------------------------
          // ESTE MÊS / MÉDIA
          // ------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  titulo: 'Este mês',
                  valor: formatarReais(resumo.totalMes),
                  icone: Icons.calendar_month_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStat(
                  titulo: 'Média por serviço',
                  valor: formatarReais(resumo.ticketMedio),
                  icone: Icons.trending_up_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ------------------------------------------------------
          // LISTA
          // ------------------------------------------------------
          const Text(
            'REPASSES POR ATENDIMENTO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cinzaTexto,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          if (resumo.atendimentos.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.history_rounded, color: cinzaTexto, size: 36),
                  SizedBox(height: 10),
                  Text(
                    'Nenhum atendimento concluído ainda.',
                    style: TextStyle(fontSize: 14, color: cinzaTexto),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Fique online e aceite chamados para começar.',
                    style: TextStyle(fontSize: 12, color: cinzaTexto),
                  ),
                ],
              ),
            )
          else
            ...resumo.atendimentos.map(_buildAtendimento),
        ],
      ),
    );
  }

  Widget _buildStat({
    required String titulo,
    required String valor,
    required IconData icone,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: azulPrincipal, size: 20),
          const SizedBox(height: 10),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: pretoPrincipal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: const TextStyle(fontSize: 12, color: cinzaTexto),
          ),
        ],
      ),
    );
  }

  Widget _buildAtendimento(AtendimentoConcluido item) {
    final ehPix = item.formaPagamento == 'Pix';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.servico,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: pretoPrincipal,
                  ),
                ),
              ),
              Text(
                formatarReais(item.valor),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: verde,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.nomeCliente,
            style: const TextStyle(fontSize: 13, color: pretoPrincipal),
          ),
          const SizedBox(height: 2),
          Text(
            item.endereco,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: cinzaTexto),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (ehPix ? azulPrincipal : verde).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.formaPagamento.isEmpty ? '—' : item.formaPagamento,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ehPix ? azulPrincipal : verde,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatarData(item.concluidoEm),
                style: const TextStyle(fontSize: 11, color: cinzaTexto),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
