import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/controllers/auth_controller.dart';

/// Perguntas frequentes e canais de contato.
/// Serve para cliente e socorrista (as perguntas mudam pelo tipo).
class AjudaSuporteScreen extends StatelessWidget {
  const AjudaSuporteScreen({super.key});

  static const Color azulPrincipal = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto = Color(0xFF8A8A8A);
  static const Color cinzaFundo = Color(0xFFF5F5F5);

  // ------------------------------------------------------------
  // CONTATOS DE SUPORTE
  // Troque pelos canais reais do projeto.
  // ------------------------------------------------------------
  static const String emailSuporte = 'suporte@hook.app';
  static const String whatsappSuporte = '(00) 00000-0000';

  static const List<_Pergunta> _perguntasCliente = [
    _Pergunta(
      'Como peço um guincho?',
      'Na tela inicial, confira o ponto de encontro, escolha o veículo e o '
          'tipo de serviço e toque em "Solicitar Resgate". Depois é só '
          'confirmar o resumo e acompanhar o socorrista no mapa.',
    ),
    _Pergunta(
      'Quanto custa o serviço?',
      'O valor estimado aparece antes de você confirmar o pedido. Ele varia '
          'conforme o tipo de guincho (leve ou pesado) e o serviço escolhido.',
    ),
    _Pergunta(
      'Como pago o socorrista?',
      'Você escolhe Pix ou dinheiro ao fazer o pedido. Em "Perfil > Forma de '
          'pagamento" dá para definir a opção que vem marcada por padrão.',
    ),
    _Pergunta(
      'Posso cancelar um pedido?',
      'Sim. Enquanto o app estiver procurando ou acompanhando o socorrista, '
          'toque em "Cancelar" na tela de acompanhamento.',
    ),
    _Pergunta(
      'Para que servem os endereços salvos?',
      'Para pedir socorro mais rápido em lugares que você usa sempre, como '
          'casa ou trabalho. Cadastre em "Perfil > Endereços salvos" e use o '
          'atalho "Usar endereço salvo" na tela inicial.',
    ),
  ];

  static const List<_Pergunta> _perguntasSocorrista = [
    _Pergunta(
      'Como recebo chamados?',
      'Na tela inicial, ative o botão "Online". Os chamados próximos aparecem '
          'na lista, do mais perto para o mais distante, e você escolhe qual '
          'aceitar.',
    ),
    _Pergunta(
      'O que acontece quando aceito um chamado?',
      'O app abre a rota até o cliente e mostra os botões de status: '
          '"Cheguei ao local", "Iniciar atendimento" e "Finalizar". O cliente '
          'acompanha cada etapa.',
    ),
    _Pergunta(
      'Onde vejo quanto ganhei?',
      'Em "Perfil > Ganhos e repasses" ou na aba "Histórico". Lá ficam o total '
          'recebido, o total do mês e o valor de cada atendimento concluído.',
    ),
    _Pergunta(
      'Como mudo a placa ou o tipo do guincho?',
      'Em "Perfil > Meus dados". Esses dados ficam no seu cadastro e '
          'identificam o seu guincho para a equipe do Hook.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final perguntas = AuthController.instance.ehMotorista
        ? _perguntasSocorrista
        : _perguntasCliente;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: pretoPrincipal),
        ),
        title: const Text(
          'Ajuda e suporte',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: pretoPrincipal,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'PERGUNTAS FREQUENTES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cinzaTexto,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...perguntas.map(_buildPergunta),
          const SizedBox(height: 28),
          const Text(
            'FALE COM A GENTE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cinzaTexto,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildContato(
            context,
            icone: Icons.mail_outline_rounded,
            titulo: 'E-mail',
            valor: emailSuporte,
          ),
          _buildContato(
            context,
            icone: Icons.chat_outlined,
            titulo: 'WhatsApp',
            valor: whatsappSuporte,
          ),
          const SizedBox(height: 8),
          const Text(
            'Atendimento de segunda a sexta, das 8h às 18h.',
            style: TextStyle(fontSize: 12, color: cinzaTexto),
          ),
        ],
      ),
    );
  }

  Widget _buildPergunta(_Pergunta pergunta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Theme(
        // Tira as linhas divisórias padrão do ExpansionTile.
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: azulPrincipal,
          collapsedIconColor: cinzaTexto,
          title: Text(
            pergunta.titulo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: pretoPrincipal,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                pergunta.resposta,
                style: const TextStyle(
                  fontSize: 14,
                  color: cinzaTexto,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContato(
    BuildContext context, {
    required IconData icone,
    required String titulo,
    required String valor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: cinzaFundo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icone, color: azulPrincipal, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 12, color: cinzaTexto),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: pretoPrincipal,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar',
            icon: const Icon(Icons.copy_rounded, color: cinzaTexto, size: 20),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: valor));

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$titulo copiado.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Pergunta {
  final String titulo;
  final String resposta;

  const _Pergunta(this.titulo, this.resposta);
}
