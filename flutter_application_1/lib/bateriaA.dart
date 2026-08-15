import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Importe a nova página que criaremos abaixo
// import 'package:seu_projeto/car_selection_page.dart';

class BateriaA extends StatefulWidget {
  const BateriaA({super.key});

  @override
  State<BateriaA> createState() => _BateriaAState();
}

class _BateriaAState extends State<BateriaA> {
  // Estado para controlar qual sintoma está selecionado.
  String? _selectedSymptom = "Weak panel lights";

  // Controladores de tamanho para o card arrastável
  final double _initialSize = 0.50; // Começa ocupando 50% da altura da tela
  final double _minSize = 0.35;    // Tamanho mínimo ao arrastar para baixo (mantém título visível)
  final double _maxSize = 0.90;    // Tamanho máximo ao arrastar para cima

  @override
  Widget build(BuildContext context) {
    // Definindo cores personalizadas com base na imagem.
    const Color primaryColor = Color(0xFF26C6DA); // Azul-petróleo claro
    const Color darkColor = Colors.black;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Mapa de fundo (Google Maps)
          // Nota: Você precisará de uma chave de API para renderizar o mapa real.
          // O padding inferior garante que a logo do Google e botões do mapa 
          // não fiquem escondidos atrás do card quando ele estiver no tamanho mínimo.
          const GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(37.5606, -122.2858), // Foster City, CA
              zoom: 14.0,
            ),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            padding: EdgeInsets.only(bottom: 250), // Ajuste conforme necessário
          ),

          // 2. Card inferior arrastável (DraggableScrollableSheet)
          DraggableScrollableSheet(
            initialChildSize: _initialSize,
            minChildSize: _minSize,
            maxChildSize: _maxSize,
            // 'snap' faz o card grudar nos tamanhos definidos ao invés de flutuar livremente
            snap: true, 
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    )
                  ],
                ),
                // Usamos um ListView aqui. O 'scrollController' é essencial.
                // É ele que diz ao DraggableScrollableSheet quando deve 
                // arrastar a folha inteira e quando deve rolar o conteúdo interno.
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Alça de arrasto central
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),

                    // Título principal
                    const Text(
                      "Assitencia de bateria arriada",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtítulo
                    const Text(
                      "O QUE O VEÍCULO APRESENTA?",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Seleção de sintomas (Wrap com chips)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildSymptomChip("Weak panel lights"),
                        _buildSymptomChip("Motor doesn't turn"),
                        _buildSymptomChip("Clicks on ignition"),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 4. Card do Veículo (Botão de redirecionamento)
                    Material(
                      elevation: 0,
                      color: const Color(0xFFE0F7FA), // Azul-petróleo claro
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          // Redireciona para a página de seleção de carro
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SizedBox.shrink()),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.flash_on_outlined, color: primaryColor, size: 28),
                              const SizedBox(width: 16),
                              const Text(
                                "Toyota Corolla",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: darkColor,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.edit_outlined, color: primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 5. Detalhes do Serviço
                    _buildServiceDetailRow("Serviço", "Carga de Bateria"),
                    _buildServiceDetailRow("Valor Estimado", "R\$ 120,00", isPrice: true, priceColor: primaryColor),
                    _buildServiceDetailRow("Tempo de Chegada", "10-15 min"),
                    const SizedBox(height: 32),

                    // 6. Botão Confirmar
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          // Ação de confirmação
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text("Confirmar"),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper widget para criar cada chip de sintoma (permanece igual)
  Widget _buildSymptomChip(String symptomText) {
    bool isSelected = _selectedSymptom == symptomText;
    return ChoiceChip(
      label: Text(symptomText),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedSymptom = selected ? symptomText : null;
        });
      },
      selectedColor: Colors.black,
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      showCheckmark: false,
    );
  }

  // Helper widget para criar cada linha de detalhe do serviço (permanece igual)
  Widget _buildServiceDetailRow(String label, String value, {bool isPrice = false, Color priceColor = Colors.cyan}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isPrice ? priceColor : Colors.black,
            ),
          ),
        ],
          ),
        );
  }
}