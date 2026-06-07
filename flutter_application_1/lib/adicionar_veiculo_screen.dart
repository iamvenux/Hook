import 'package:flutter/material.dart';

class AdicionarVeiculoScreen extends StatefulWidget {
  const AdicionarVeiculoScreen({super.key});

  @override
  State<AdicionarVeiculoScreen> createState() => _AdicionarVeiculoScreenState();
}

class _AdicionarVeiculoScreenState extends State<AdicionarVeiculoScreen> {
  static const Color azulPrincipal = Color(0xFF1A7EF5);
  static const Color pretoPrincipal = Color(0xFF1A1A1A);
  static const Color cinzaTexto = Color(0xFF8A8A8A);
  static const Color cinzaFundo = Color(0xFFF5F5F5);

  int _tipoSelecionado = 0;
  String? _corSelecionada;

  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anoController = TextEditingController();
  final _placaController = TextEditingController();

  final List<Map<String, dynamic>> _tipos = [
    {'label': 'Carro', 'icon': Icons.directions_car_rounded},
    {'label': 'Moto', 'icon': Icons.two_wheeler_rounded},
    {'label': 'SUV', 'icon': Icons.airport_shuttle_rounded},
  ];

  final List<String> _cores = [
    'Branco', 'Preto', 'Prata', 'Cinza', 'Vermelho',
    'Azul', 'Verde', 'Amarelo', 'Laranja', 'Marrom',
  ];

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    _anoController.dispose();
    _placaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: pretoPrincipal),
        ),
        title: const Text(
          'Adicionar seu Veículo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: pretoPrincipal,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo de Veículo
                  const Text(
                    'TIPO DE VEÍCULO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cinzaTexto,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(_tipos.length, (index) {
                      final selecionado = _tipoSelecionado == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _tipoSelecionado = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(
                                right: index < _tipos.length - 1 ? 10 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selecionado
                                  ? azulPrincipal.withOpacity(0.07)
                                  : cinzaFundo,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selecionado
                                    ? azulPrincipal
                                    : Colors.transparent,
                                width: 1.8,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _tipos[index]['icon'] as IconData,
                                  size: 28,
                                  color: selecionado
                                      ? azulPrincipal
                                      : pretoPrincipal,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _tipos[index]['label'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selecionado
                                        ? azulPrincipal
                                        : pretoPrincipal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // Marca
                  _buildLabel('Marca'),
                  const SizedBox(height: 8),
                  _buildInput(
                    controller: _marcaController,
                    hint: 'ex: Toyota',
                    icon: Icons.verified_rounded,
                  ),

                  const SizedBox(height: 20),

                  // Modelo
                  _buildLabel('Modelo'),
                  const SizedBox(height: 8),
                  _buildInput(
                    controller: _modeloController,
                    hint: 'ex: Corolla',
                    icon: Icons.edit_rounded,
                  ),

                  const SizedBox(height: 20),

                  // Ano e Placa lado a lado
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Ano'),
                            const SizedBox(height: 8),
                            _buildInput(
                              controller: _anoController,
                              hint: '2022',
                              icon: Icons.calendar_month_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Placa'),
                            const SizedBox(height: 8),
                            _buildInput(
                              controller: _placaController,
                              hint: 'ABC-1234',
                              icon: Icons.pin_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Cor do Veículo
                  _buildLabel('Cor do Veículo'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: cinzaFundo,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _corSelecionada,
                        hint: const Text(
                          'Selecione a cor',
                          style:
                              TextStyle(color: cinzaTexto, fontSize: 15),
                        ),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: cinzaTexto),
                        items: _cores
                            .map((cor) => DropdownMenuItem(
                                  value: cor,
                                  child: Text(cor),
                                ))
                            .toList(),
                        onChanged: (valor) =>
                            setState(() => _corSelecionada = valor),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Botão Salvar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {},
                label: const Text(
                  'SALVAR VEÍCULO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pretoPrincipal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: pretoPrincipal,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: pretoPrincipal),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: cinzaTexto),
        prefixIcon: Icon(icon, color: cinzaTexto, size: 20),
        filled: true,
        fillColor: cinzaFundo,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}