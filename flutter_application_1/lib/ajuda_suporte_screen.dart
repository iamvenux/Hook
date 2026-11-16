import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color _azul = Color(0xFF1A7EF5);
const Color _azulEscuro = Color(0xFF1565D8);
const Color _azulClaro = Color(0xFFE8F2FE);
const Color _preto = Color(0xFF1A1A1A);
const Color _cinzaTexto = Color(0xFF8A8A8A);
const Color _cinzaFundo = Color(0xFFF5F5F5);
const Color _borda = Color(0xFFEEEEEE);

// Contatos de exemplo (substituir pelos reais quando existirem).
const String _emailSuporte = 'suporte@hook.app.br';
const String _telefoneSuporte = '(11) 4000-1234';

class _Pergunta {
  final String categoria;
  final String pergunta;
  final String resposta;

  const _Pergunta(this.categoria, this.pergunta, this.resposta);
}

class _Assunto {
  final String nome;
  final IconData icone;

  const _Assunto(this.nome, this.icone);
}

const List<_Assunto> _assuntosCliente = [
  _Assunto('Pedidos', Icons.local_shipping_outlined),
  _Assunto('Pagamento', Icons.payments_outlined),
  _Assunto('Conta', Icons.person_outline_rounded),
  _Assunto('Segurança', Icons.shield_outlined),
];

const List<_Assunto> _assuntosMotorista = [
  _Assunto('Atendimentos', Icons.local_shipping_outlined),
  _Assunto('Recebimentos', Icons.payments_outlined),
  _Assunto('Conta', Icons.person_outline_rounded),
  _Assunto('Segurança', Icons.shield_outlined),
];

const List<_Pergunta> _perguntasCliente = [
  _Pergunta(
    'Pedidos',
    'Como peço um guincho?',
    'Na tela inicial, confira o ponto de encontro e o veículo, escolha o '
        'tipo de reboque (leve ou pesado) e toque em "Solicitar Resgate". '
        'Depois é só revisar o resumo, escolher a forma de pagamento e '
        'confirmar o pedido.',
  ),
  _Pergunta(
    'Pedidos',
    'Como o valor é calculado?',
    'O valor depende do tipo de guincho e da distância do trajeto: uma '
        'taxa base mais um valor por quilômetro, com um mínimo para cada '
        'tipo. Você vê o valor estimado antes de confirmar o pedido.',
  ),
  _Pergunta(
    'Pedidos',
    'Qual a diferença entre guincho leve e pesado?',
    'O guincho leve atende veículos de passeio, como carros, SUVs e '
        'motos, de até 3,5 toneladas. O guincho pesado atende caminhões, '
        'ônibus e veículos maiores.',
  ),
  _Pergunta(
    'Pedidos',
    'Posso cancelar um pedido?',
    'Sim. Na tela de acompanhamento, toque em "Cancelar resgate". Se o '
        'motorista já estiver a caminho, ele é avisado na hora.',
  ),
  _Pergunta(
    'Pedidos',
    'Nenhum motorista aceitou meu pedido. E agora?',
    'Os motoristas disponíveis mais próximos são avisados. Se ninguém '
        'aceitar em alguns minutos, cancele e faça um novo pedido. '
        'Conferir se o ponto de encontro está certo também ajuda.',
  ),
  _Pergunta(
    'Pagamento',
    'Quais são as formas de pagamento?',
    'Você pode pagar com Pix ou em dinheiro. A forma é escolhida no '
        'resumo do pedido, antes de confirmar.',
  ),
  _Pergunta(
    'Pagamento',
    'Como funciona o troco?',
    'Ao escolher dinheiro, informe para quanto você precisa de troco. '
        'O motorista é avisado e já leva o valor certo.',
  ),
  _Pergunta(
    'Pagamento',
    'O valor final pode mudar?',
    'O valor mostrado no pedido é uma estimativa feita pela distância '
        'do trajeto. Qualquer combinação diferente deve ser feita com o '
        'motorista antes de iniciar o atendimento.',
  ),
  _Pergunta(
    'Conta',
    'Como altero meus dados?',
    'Vá em Perfil e toque em "Editar perfil". Lá você troca nome, foto e '
        'telefone. Para trocar o e-mail, enviamos um código de confirmação '
        'para o novo endereço.',
  ),
  _Pergunta(
    'Conta',
    'Esqueci minha senha. O que faço?',
    'Na tela de login, toque em "Esqueceu a senha?" e informe seu '
        'e-mail. Enviaremos um código para você criar uma nova senha. '
        'Se você ainda lembra da senha, pode trocá-la em Perfil > '
        'Configurações.',
  ),
  _Pergunta(
    'Conta',
    'Como cadastro ou removo um veículo?',
    'Na aba Veículos, toque em "Adicionar veículo" para cadastrar. Para '
        'editar, definir como padrão ou excluir, use o menu (três pontos) '
        'no cartão do veículo.',
  ),
  _Pergunta(
    'Conta',
    'Como salvo endereços como casa e trabalho?',
    'Em Perfil > Endereços salvos você adiciona locais frequentes. Na '
        'hora de pedir ajuda, eles aparecem como atalhos no ponto de '
        'encontro.',
  ),
  _Pergunta(
    'Segurança',
    'Como sei que o motorista é o certo?',
    'Na tela de acompanhamento você vê o nome, a foto e a placa do '
        'guincho. Confira esses dados antes de entregar o veículo.',
  ),
  _Pergunta(
    'Segurança',
    'Meus dados estão protegidos?',
    'Sua senha é guardada de forma criptografada e a localização é usada '
        'apenas para encontrar o motorista e acompanhar o atendimento.',
  ),
];

const List<_Pergunta> _perguntasMotorista = [
  _Pergunta(
    'Atendimentos',
    'Como começo a receber chamados?',
    'Na aba Chamados, ative o status "Você está online". Os chamados '
        'próximos aparecem na lista, dos mais próximos para os mais '
        'distantes.',
  ),
  _Pergunta(
    'Atendimentos',
    'Como aceito um chamado?',
    'Toque em "Aceitar chamado" e confirme. O cliente é avisado na hora '
        'e você segue pela rota até o ponto de encontro.',
  ),
  _Pergunta(
    'Atendimentos',
    'Quais são as etapas do atendimento?',
    'A caminho, "Cheguei ao local", "Iniciar atendimento" e "Finalizar '
        'atendimento". Cada etapa atualiza o cliente em tempo real.',
  ),
  _Pergunta(
    'Atendimentos',
    'Não posso mais atender. Posso cancelar?',
    'Pode, pela tela de rota. O pedido é cancelado também para o '
        'cliente, então use apenas quando realmente não for possível '
        'atender.',
  ),
  _Pergunta(
    'Recebimentos',
    'Como sei quanto vou receber?',
    'O valor do atendimento aparece no chamado antes de você aceitar, '
        'junto com a distância e a forma de pagamento.',
  ),
  _Pergunta(
    'Recebimentos',
    'O cliente vai pagar em dinheiro. E o troco?',
    'Quando o cliente pede troco, o chamado indica para quanto. Leve o '
        'valor em notas menores para facilitar.',
  ),
  _Pergunta(
    'Conta',
    'Como altero meus dados e minha foto?',
    'Em Perfil, toque em "Meus dados". Lá você troca nome, foto e '
        'telefone. Para trocar o e-mail, enviamos um código para o novo '
        'endereço.',
  ),
  _Pergunta(
    'Conta',
    'Como troco minha senha?',
    'Vá em Perfil > Configurações > Alterar senha. Você precisa informar '
        'a senha atual e a nova senha.',
  ),
  _Pergunta(
    'Segurança',
    'Como confirmo que estou atendendo a pessoa certa?',
    'Confira o nome do cliente e o veículo (modelo e placa) no chamado '
        'antes de iniciar o atendimento.',
  ),
  _Pergunta(
    'Segurança',
    'Posso falar com o cliente?',
    'Sim, pelo chat do próprio aplicativo, durante o atendimento. Prefira '
        'sempre esse canal para manter tudo registrado.',
  ),
];

/// Tela de Ajuda e suporte, para cliente e motorista.
class AjudaSuporteScreen extends StatefulWidget {
  final bool motorista;

  const AjudaSuporteScreen({super.key, this.motorista = false});

  @override
  State<AjudaSuporteScreen> createState() => _AjudaSuporteScreenState();
}

class _AjudaSuporteScreenState extends State<AjudaSuporteScreen> {
  final _buscaController = TextEditingController();

  String? _assunto;
  int? _aberta;

  List<_Assunto> get _assuntos =>
      widget.motorista ? _assuntosMotorista : _assuntosCliente;

  List<_Pergunta> get _perguntas =>
      widget.motorista ? _perguntasMotorista : _perguntasCliente;

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  String _normalizar(String t) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';

    var r = t.toLowerCase();

    for (var i = 0; i < de.length; i++) {
      r = r.replaceAll(de[i], para[i]);
    }

    return r;
  }

  List<_Pergunta> get _filtradas {
    final termo = _normalizar(_buscaController.text.trim());

    return _perguntas.where((p) {
      if (_assunto != null && p.categoria != _assunto) return false;

      if (termo.isEmpty) return true;

      return _normalizar('${p.pergunta} ${p.resposta}').contains(termo);
    }).toList();
  }

  void _copiar(String rotulo, String valor) {
    Clipboard.setData(ClipboardData(text: valor));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$rotulo copiado: $valor')),
    );
  }

  void _chat() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: _azulClaro,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded,
                    color: _azul, size: 26),
              ),
              const SizedBox(height: 14),
              const Text(
                'Chat com o suporte',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _preto,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'O atendimento por chat estará disponível em breve. '
                'Enquanto isso, fale com a gente por e-mail ou telefone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _cinzaTexto),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _azul,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Entendi',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtradas;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _preto),
        title: const Text(
          'Ajuda e suporte',
          style: TextStyle(color: _preto, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            const Text(
              'Como podemos ajudar?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _preto,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Busque uma dúvida ou escolha um assunto.',
              style: TextStyle(fontSize: 14, color: _cinzaTexto),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _buscaController,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() => _aberta = null),
              decoration: InputDecoration(
                hintText: 'Buscar nas perguntas frequentes',
                hintStyle: const TextStyle(color: _cinzaTexto),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: _cinzaTexto),
                suffixIcon: _buscaController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: _cinzaTexto, size: 20),
                        onPressed: () => setState(() {
                          _buscaController.clear();
                          _aberta = null;
                        }),
                      ),
                filled: true,
                fillColor: _cinzaFundo,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _azul, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ASSUNTOS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _cinzaTexto,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < _assuntos.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _cartaoAssunto(_assuntos[i])),
                ],
              ],
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _assunto == null
                      ? 'PERGUNTAS FREQUENTES'
                      : _assunto!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _cinzaTexto,
                    letterSpacing: 1.2,
                  ),
                ),
                if (_assunto != null)
                  GestureDetector(
                    onTap: () => setState(() {
                      _assunto = null;
                      _aberta = null;
                    }),
                    child: const Text(
                      'Ver todas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _azul,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (lista.isEmpty)
              _vazio()
            else
              for (var i = 0; i < lista.length; i++) _itemFaq(i, lista[i]),
            const SizedBox(height: 20),
            _cartaoContato(),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Hook · versão 1.0.0',
                style: TextStyle(fontSize: 12, color: _cinzaTexto),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartaoAssunto(_Assunto a) {
    final ativo = _assunto == a.nome;

    return InkWell(
      onTap: () => setState(() {
        _assunto = ativo ? null : a.nome;
        _aberta = null;
      }),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: ativo ? _azulClaro : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ativo ? _azul : _borda,
            width: ativo ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(a.icone, color: ativo ? _azul : _preto, size: 24),
            const SizedBox(height: 6),
            Text(
              a.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ativo ? _azul : _preto,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemFaq(int indice, _Pergunta p) {
    final aberta = _aberta == indice;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: aberta ? _azulClaro.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: aberta ? _azul : _borda),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _aberta = aberta ? null : indice),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.pergunta,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _preto,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: aberta ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _cinzaTexto,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: aberta
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          p.resposta,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vazio() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: _cinzaFundo,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: _cinzaTexto),
          SizedBox(height: 10),
          Text(
            'Nenhuma pergunta encontrada',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _preto,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tente outras palavras ou fale com o nosso suporte abaixo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _cinzaTexto),
          ),
        ],
      ),
    );
  }

  Widget _cartaoContato() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_azul, _azulEscuro],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.support_agent_rounded, color: Colors.white, size: 26),
              SizedBox(width: 10),
              Text(
                'Ainda precisa de ajuda?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Nossa equipe responde em até 1 dia útil.',
            style: TextStyle(fontSize: 14, color: Color(0xFFD6E8FD)),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.schedule_rounded, color: Color(0xFFD6E8FD), size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Seg a sex, 8h às 18h · Sáb, 8h às 12h',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFFD6E8FD)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _botaoContato(
                  Icons.chat_bubble_outline_rounded,
                  'Chat',
                  _chat,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _botaoContato(
                  Icons.mail_outline_rounded,
                  'E-mail',
                  () => _copiar('E-mail', _emailSuporte),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _botaoContato(
                  Icons.phone_outlined,
                  'Ligar',
                  () => _copiar('Telefone', _telefoneSuporte),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botaoContato(IconData icone, String rotulo, VoidCallback aoTocar) {
    return InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: _azul, size: 18),
            const SizedBox(width: 6),
            Text(
              rotulo,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _azul,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
