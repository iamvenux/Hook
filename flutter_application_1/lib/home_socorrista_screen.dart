import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'rota_socorrista_screen.dart';
import 'perfil_socorrista_screen.dart';

class ChamadoDisponivel {
  final int id;
  final String nomeUsuario;
  final String servico;
  final String icone;
  final double distanciaKm;
  final String endereco;
  final DateTime criadoEm;

  const ChamadoDisponivel({
    required this.id,
    required this.nomeUsuario,
    required this.servico,
    required this.icone,
    required this.distanciaKm,
    required this.endereco,
    required this.criadoEm,
  });
}

final List<ChamadoDisponivel> _mockChamados = [
  ChamadoDisponivel(
    id: 1,
    nomeUsuario: 'Carlos Mendes',
    servico: 'Troca de pneu',
    icone: 'tire',
    distanciaKm: 1.2,
    endereco: 'Rod. Raposo Tavares, km 68 — Alumínio/SP',
    criadoEm: DateTime.now().subtract(const Duration(minutes: 3)),
  ),
  ChamadoDisponivel(
    id: 2,
    nomeUsuario: 'Fernanda Lima',
    servico: 'Recarga de bateria',
    icone: 'battery',
    distanciaKm: 3.7,
    endereco: 'Av. Vereador José Diniz, 200 — São Roque/SP',
    criadoEm: DateTime.now().subtract(const Duration(minutes: 8)),
  ),
  ChamadoDisponivel(
    id: 3,
    nomeUsuario: 'Ricardo Souza',
    servico: 'Abastecimento de emergência',
    icone: 'gas',
    distanciaKm: 5.1,
    endereco: 'SP-280, próx. posto Shell — Mairinque/SP',
    criadoEm: DateTime.now().subtract(const Duration(minutes: 15)),
  ),
  ChamadoDisponivel(
    id: 4,
    nomeUsuario: 'Ana Paula Costa',
    servico: 'Chaveiro automotivo',
    icone: 'key',
    distanciaKm: 2.4,
    endereco: 'Rua das Flores, 45 — São Roque/SP',
    criadoEm: DateTime.now().subtract(const Duration(minutes: 21)),
  ),
];

class HomeSocorristaScreen extends StatefulWidget {
  const HomeSocorristaScreen({super.key});

  @override
  State<HomeSocorristaScreen> createState() => _HomeSocorristaScreenState();
}

class _HomeSocorristaScreenState extends State<HomeSocorristaScreen> {
  static const Color azulPrincipal  = Color(0xFF1A7EF5);
  static const Color cinzaTexto     = Color(0xFF8A8A8A);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaFundo     = Color(0xFFF5F5F5);
  static const Color verdeOnline    = Color(0xFF22C55E);
  static const Color cinzaOffline   = Color(0xFFB0B0B0);

  bool _online     = false;
  bool _carregando = false;
  int  _tabIndex   = 0;

  final String _nomeSocorrista = 'João Silva';
  final String _tipoAtuacao    = 'Autônomo';

  List<ChamadoDisponivel> get _chamados => _online ? _mockChamados : [];

  Future<void> _toggleOnline(bool valor) async {
    setState(() => _carregando = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _online     = valor;
      _carregando = false;
    });
  }

  Future<void> _aceitarChamado(ChamadoDisponivel chamado) async {
    final confirmar = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ModalConfirmarAceite(chamado: chamado),
    );

    if (confirmar == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RotaSocorristaScreen(
            chamado: ChamadoAceito(
              id: chamado.id,
              nomeUsuario: chamado.nomeUsuario,
              servico: chamado.servico,
              coordenadaUsuario: const LatLng(-23.5, -47.1),
              enderecoUsuario: chamado.endereco,
              distanciaKm: chamado.distanciaKm,
            ),
            coordenadaSocorrista: const LatLng(-23.49, -47.09),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cinzaFundo,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_tabIndex != 2) _buildToggleOnline(),
            Expanded(
              child: _tabIndex == 0
                  ? _buildListaChamados()
                  : _tabIndex == 1
                      ? _buildHistorico()
                      : PerfilSocorristaScreen(
                          nome: _nomeSocorrista,
                          tipoAtuacao: _tipoAtuacao,
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E8FF7), Color(0xFF1565D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _nomeSocorrista[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${_nomeSocorrista.split(' ').first}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: pretoPrincipal,
                  ),
                ),
                Text(
                  _tipoAtuacao,
                  style: const TextStyle(fontSize: 13, color: cinzaTexto),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined,
                    color: pretoPrincipal, size: 24),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOnline() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _carregando
                  ? cinzaTexto
                  : (_online ? verdeOnline : cinzaOffline),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _carregando
                      ? 'Atualizando...'
                      : (_online ? 'Você está online' : 'Você está offline'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _online ? pretoPrincipal : cinzaTexto,
                  ),
                ),
                Text(
                  _online
                      ? 'Recebendo chamados nas proximidades'
                      : 'Ative para receber chamados',
                  style: const TextStyle(fontSize: 12, color: cinzaTexto),
                ),
              ],
            ),
          ),
          _carregando
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: azulPrincipal),
                )
              : Switch(
                  value: _online,
                  onChanged: _toggleOnline,
                  activeColor: verdeOnline,
                  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                  thumbColor: WidgetStateProperty.all(Colors.white),
                ),
        ],
      ),
    );
  }

  Widget _buildListaChamados() {
    if (!_online) {
      return _buildEstadoVazio(
        icon: Icons.wifi_off_rounded,
        titulo: 'Você está offline',
        subtitulo: 'Ative o toggle acima para\ncomeçar a receber chamados.',
      );
    }

    if (_chamados.isEmpty) {
      return _buildEstadoVazio(
        icon: Icons.search_off_rounded,
        titulo: 'Nenhum chamado por perto',
        subtitulo: 'Aguarde. Novos chamados\naparecerão aqui automaticamente.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Row(
            children: [
              Text(
                '${_chamados.length} chamado${_chamados.length > 1 ? 's' : ''} disponível${_chamados.length > 1 ? 'is' : ''}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: pretoPrincipal,
                ),
              ),
              const Spacer(),
              const Text(
                'Mais próximos primeiro',
                style: TextStyle(fontSize: 12, color: cinzaTexto),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: _chamados.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _CardChamado(
              chamado: _chamados[i],
              onAceitar: () => _aceitarChamado(_chamados[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorico() {
    return _buildEstadoVazio(
      icon: Icons.history_rounded,
      titulo: 'Histórico de atendimentos',
      subtitulo: 'Seus chamados concluídos\naparecerão aqui.',
    );
  }

  Widget _buildEstadoVazio({
    required IconData icon,
    required String titulo,
    required String subtitulo,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(icon, size: 32, color: cinzaTexto),
          ),
          const SizedBox(height: 16),
          Text(titulo,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: pretoPrincipal)),
          const SizedBox(height: 6),
          Text(subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: cinzaTexto)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: Colors.white,
        selectedItemColor: azulPrincipal,
        unselectedItemColor: cinzaTexto,
        elevation: 0,
        selectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Chamados',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _CardChamado extends StatelessWidget {
  final ChamadoDisponivel chamado;
  final VoidCallback onAceitar;

  static const Color azulPrincipal  = Color(0xFF1A7EF5);
  static const Color cinzaTexto     = Color(0xFF8A8A8A);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);

  const _CardChamado({required this.chamado, required this.onAceitar});

  IconData get _icone {
    switch (chamado.icone) {
      case 'tire':    return Icons.tire_repair_rounded;
      case 'battery': return Icons.battery_charging_full_rounded;
      case 'gas':     return Icons.local_gas_station_rounded;
      case 'key':     return Icons.key_rounded;
      default:        return Icons.build_rounded;
    }
  }

  String get _tempoAtras {
    final diff = DateTime.now().difference(chamado.criadoEm).inMinutes;
    if (diff < 1) return 'agora';
    if (diff == 1) return 'há 1 min';
    return 'há $diff min';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: azulPrincipal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(_icone, color: azulPrincipal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chamado.nomeUsuario,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: pretoPrincipal,
                        ),
                      ),
                      Text(
                        chamado.servico,
                        style: const TextStyle(fontSize: 13, color: cinzaTexto),
                      ),
                    ],
                  ),
                ),
                Text(
                  _tempoAtras,
                  style: const TextStyle(fontSize: 12, color: cinzaTexto),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: cinzaTexto),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    chamado.endereco,
                    style: const TextStyle(fontSize: 13, color: cinzaTexto),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${chamado.distanciaKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: azulPrincipal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onAceitar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulPrincipal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text(
                  'Aceitar chamado',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalConfirmarAceite extends StatelessWidget {
  final ChamadoDisponivel chamado;

  static const Color azulPrincipal  = Color(0xFF1A7EF5);
  static const Color cinzaTexto     = Color(0xFF8A8A8A);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);

  const _ModalConfirmarAceite({required this.chamado});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Confirmar aceite',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: pretoPrincipal,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ao aceitar, você se compromete a atender este chamado.',
            style: TextStyle(fontSize: 14, color: cinzaTexto),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildLinha(Icons.person_outline_rounded, 'Usuário', chamado.nomeUsuario),
                const SizedBox(height: 10),
                _buildLinha(Icons.build_outlined, 'Serviço', chamado.servico),
                const SizedBox(height: 10),
                _buildLinha(Icons.location_on_outlined, 'Local', chamado.endereco),
                const SizedBox(height: 10),
                _buildLinha(Icons.directions_car_outlined, 'Distância',
                    '${chamado.distanciaKm.toStringAsFixed(1)} km de você'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cinzaTexto,
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulPrincipal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Confirmar aceite',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinha(IconData icon, String label, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: cinzaTexto),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 13,
                color: cinzaTexto,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(valor,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}