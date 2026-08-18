import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'overlay_endereco.dart';
import 'adicionar_veiculo_screen.dart';
import 'solicitar_servico_screen.dart';
import 'perfil_cliente_screen.dart';

void main() {
  runApp(const HookApp());
}

class HookApp extends StatelessWidget {
  const HookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A7EF5)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color azulPrincipal = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto = Color(0xFF8A8A8A);
  static const Color cinzaFundo = Color(0xFFF5F5F5);

  int _navSelecionado = 0;
  int _tipoReboque = 0;
  int _veiculoSelecionado = 0;
  String _enderecoAtual = 'Av. Paulista, 1200';
  LatLng? _coordenadaAtual;

  // TODO: isso ainda é mockado — troque por ApiService.instance.listarVeiculos()
  // quando integrar essa tela (o 'id' abaixo é só placeholder pra o app
  // compilar e testar o fluxo; troque pelos ids reais vindos da API).
  final List<Map<String, String>> _veiculos = [
    {'id': '1', 'nome': 'Toyota Corolla', 'placa': 'BRA-2E19', 'cor': 'Prata', 'ano': '2022'},
    {'id': '2', 'nome': 'Jeep Renegade', 'placa': 'ABC-1234', 'cor': 'Preto', 'ano': '2021'},
  ];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_navSelecionado == 3) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const SafeArea(child: PerfilClienteScreen()),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seja Bem-vindo(a)',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: pretoPrincipal,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Como posso te ajudar hoje ?',
                    style: TextStyle(fontSize: 14, color: cinzaTexto),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildConteudoResgate(),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudoResgate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Localização
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: azulPrincipal, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: azulPrincipal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: azulPrincipal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PONTO DE ENCONTRO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cinzaTexto,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _enderecoAtual,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: azulPrincipal,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final resultado = await showGeneralDialog<dynamic>(
                    context: context,
                    barrierDismissible: false,
                    barrierColor: Colors.transparent,
                    transitionDuration: Duration.zero,
                    pageBuilder: (_, __, ___) => EnderecoOverlay(
                      enderecoAtual: _enderecoAtual,
                      coordenadaAtual: _coordenadaAtual,
                    ),
                  );
                  if (resultado != null && mounted) {
                    final r = resultado as Map<String, dynamic>;
                    setState(() {
                      _enderecoAtual = r['endereco'] as String;
                      _coordenadaAtual = LatLng(
                        r['lat'] as double,
                        r['lng'] as double,
                      );
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: pretoPrincipal,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Mudar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Seção Veículos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SEU VEÍCULO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cinzaTexto,
                letterSpacing: 1.2,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdicionarVeiculoScreen()),
                );
              },
              child: const Text(
                '+ ADICIONAR NOVO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: azulPrincipal,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            // Calcula largura real de cada card (metade da largura disponível menos o espaçamento)
            final cardWidth = (constraints.maxWidth - 12) / 2;
            // Altura mínima de 148px para comportar todo o conteúdo em telas pequenas
            final cardHeight = cardWidth.clamp(148.0, 190.0);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: cardWidth / cardHeight,
              ),
              itemCount: _veiculos.length,
              itemBuilder: (context, index) {
                final v = _veiculos[index];
                final selecionado = _veiculoSelecionado == index;
                return GestureDetector(
                  onTap: () => setState(() => _veiculoSelecionado = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selecionado
                          ? pretoPrincipal
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: selecionado
                                    ? Colors.white.withOpacity(0.15)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.directions_car_rounded,
                                color: selecionado ? Colors.white : pretoPrincipal,
                                size: 20,
                              ),
                            ),
                            if (index == 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: azulPrincipal,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'PADRÃO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          v['nome']!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: selecionado ? Colors.white : pretoPrincipal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          v['placa']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: selecionado
                                ? Colors.white.withOpacity(0.6)
                                : cinzaTexto,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 7,
                              color: selecionado
                                  ? Colors.white.withOpacity(0.5)
                                  : cinzaTexto,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '${v['cor']} • ${v['ano']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: selecionado
                                      ? Colors.white.withOpacity(0.6)
                                      : cinzaTexto,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 24),

        // Tipo de Reboque
        const Text(
          'TIPO DE REBOQUE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: cinzaTexto,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTipoReboque(0, Icons.local_shipping_rounded,
                  'Guincho Leve', 'Até 3.5 toneladas'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTipoReboque(1, Icons.rv_hookup_rounded,
                  'Guincho Pesado', 'Caminhões e ônibus'),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Botão Solicitar
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              // Usa coordenada salva ou fallback para São Paulo centro
              final coordenada = _coordenadaAtual ??
                  const LatLng(-23.5650, -46.6520);
              final tiposReboque = ['Guincho Leve', 'Guincho Pesado'];
              final veiculo = _veiculos[_veiculoSelecionado]['nome'] ?? 'Veículo';
              final veiculoId = int.parse(_veiculos[_veiculoSelecionado]['id']!);
              final servico = tiposDeReboque[tiposReboque[_tipoReboque]]!;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResumoServicoScreen(
                    servico: servico,
                    endereco: _enderecoAtual,
                    coordenada: coordenada,
                    veiculo: veiculo,
                    veiculoId: veiculoId,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: pretoPrincipal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            child: const Text(
              'Solicitar Resgate',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTipoReboque(
      int index, IconData icone, String titulo, String subtitulo) {
    final selecionado = _tipoReboque == index;
    return GestureDetector(
      onTap: () => setState(() => _tipoReboque = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: selecionado ? azulPrincipal.withOpacity(0.07) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selecionado ? azulPrincipal : const Color(0xFFDDDDDD),
            width: selecionado ? 1.8 : 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone,
                size: 30, color: selecionado ? azulPrincipal : cinzaTexto),
            const SizedBox(height: 8),
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selecionado ? pretoPrincipal : cinzaTexto,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: cinzaTexto),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return SizedBox(
      height: 80,
      child: BottomNavigationBar(
        currentIndex: _navSelecionado,
        onTap: (index) => setState(() => _navSelecionado = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: pretoPrincipal,
        selectedItemColor: azulPrincipal,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded),
            label: 'EXPLORAR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_rounded),
            label: 'ROTAS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border_rounded),
            label: 'FAVORITOS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'PERFIL',
          ),
        ],
      ),
    );
  }
}