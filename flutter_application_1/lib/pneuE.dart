import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MaterialApp(home: PneuE()));
}

class PneuE extends StatefulWidget {
  const PneuE({super.key});

  @override
  State<PneuE> createState() => _PneuEState();
}

class _PneuEState extends State<PneuE> {
  // Posição inicial para o mapa
  static const _centroMapa = LatLng(37.5585, -122.3168);
  final Set<Marker> _marcadores = {};

  // Estado das seleções das rodas (verdadeiro se selecionada, falso se não)
  final Map<int, bool> _rodasSelecionadas = {
    0: false, // Dianteira esquerda
    1: false, // Dianteira direita
    2: false, // Traseira esquerda
    3: false, // Traseira direita
  };

  // Coordenadas relativas dos botões de seleção sobre a imagem do carro (0.0 a 1.0)
  // Você pode precisar ajustar esses valores para que coincidam com as rodas da sua imagem.
  final Map<int, Offset> _posicoesBotoesRodas = {
    0: const Offset(0.60, 0.3), // Dianteira esquerda (x, y)
    1: const Offset(1.20, 0.3), // Dianteira direita
    2: const Offset(0.60, 0.7), // Traseira esquerda
    3: const Offset(1.20, 0.7), // Traseira direita
  };

  // Lógica para cálculo dinâmico (exemplos)
  double get _numRodasSelecionadas => _rodasSelecionadas.values.where((v) => v).length.toDouble();

  String get _valorEstimado {
    if (_numRodasSelecionadas == 0) return "R\$ 0,00";
    double precoBase = 50.00; // Preço base por serviço ou por roda
    double precoPorRodaAdicional = 15.00; // Custo extra por roda além da primeira
    double precoTotal = precoBase + (precoPorRodaAdicional * (_numRodasSelecionadas - 1).clamp(0, 3));
    return "R\$ ${precoTotal.toStringAsFixed(2).replaceAll('.', ',')}";
  }

  String get _tempoChegada {
    if (_numRodasSelecionadas == 0) return "0 min";
    int tempoBaseMin = 15;
    int tempoBaseMax = 20;
    int acrescimoPorRoda = 2; // minutos extras por roda

    int minFinal = tempoBaseMin + (acrescimoPorRoda * (_numRodasSelecionadas - 1).toInt().clamp(0, 3));
    int maxFinal = tempoBaseMax + (acrescimoPorRoda * (_numRodasSelecionadas - 1).toInt().clamp(0, 3));

    return "$minFinal-$maxFinal min";
  }

  void _alternarSelecaoRoda(int index) {
    setState(() {
      _rodasSelecionadas[index] = !_rodasSelecionadas[index]!;
    });
  }

  @override
  void initState() {
    super.initState();
    _marcadores.add(
      const Marker(
        markerId: MarkerId('pneu_furado'),
        position: _centroMapa,
        infoWindow: InfoWindow(title: 'Pneu Furado'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definir estilos
    const Color corPrimaria = Color(0xFF2563EB); // Azul dos ícones e textos
    const Color corFundoCardAtendimento = Color(0xFFE0F2FE); // Azul claro do banner
    const Color corFundoCardCarro = Colors.white;
    const TextStyle estiloSubtitulo = TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w400);
    const TextStyle estiloValor = TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w600);
    const TextStyle estiloValorPreco = TextStyle(fontSize: 18, color: corPrimaria, fontWeight: FontWeight.bold);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _centroMapa, zoom: 14.0),
            markers: _marcadores,
          ),

          // 2. Botão Voltar
          Positioned(
            top: 40.0,
            left: 16.0,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: Colors.white,
              elevation: 4.0,
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),

          // 3. Área Principal do Card (Solicitar troca de pneu)
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32.0), topRight: Radius.circular(32.0)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Solicitar troca de pneu",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 24.0),

                  // 4. Card do Veículo Interativo
                  Container(
                    width: double.infinity,
                    height: 250.0, // Altura fixa para o diagrama do carro
                    decoration: BoxDecoration(
                      color: corFundoCardCarro,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: Colors.grey.shade200, width: 1.0),
                      boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 5, spreadRadius: 1)],
                    ),
                    child: Stack(
                      children: [
                        // Imagem do Carro Vista Superior (Customizada)
                        Center(
                          child: 
                            Icon(
                              Icons.directions_car_filled_rounded, // Ícone de carro do Flutter
                              size: 120,                           // Tamanho do ícone
                              color: Color(0xFF2563EB),            // Cor azul (ou a cor do seu app)
                          ),
                        ),

                        // Círculos de Seleção de Rodas sobrepostos
                        ..._posicoesBotoesRodas.entries.map((entry) {
                          int index = entry.key;
                          Offset posicao = entry.value;
                          bool selecionada = _rodasSelecionadas[index]!;

                          return Positioned(
                            left: posicao.dx * 250.0 - 16.0, // Ajuste para centralizar o botão
                            top: posicao.dy * 250.0 - 16.0,  // Ajuste para centralizar o botão
                            child: InkWell(
                              onTap: () => _alternarSelecaoRoda(index),
                              borderRadius: BorderRadius.circular(16.0),
                              child: Container(
                                width: 32.0,
                                height: 32.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selecionada ? corPrimaria : Colors.white,
                                  border: Border.all(color: corPrimaria, width: 2.0),
                                ),
                                child: selecionada
                                    ? const Icon(Icons.check, color: Colors.white, size: 20.0)
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  const Center(child: Text("Selecione uma ou mais rodas para a troca:", style: estiloSubtitulo)),
                  const SizedBox(height: 24.0),

                  // 5. Banner de Confirmação de Pneu Reserva
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: corFundoCardAtendimento,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: corPrimaria),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            "Você confirmou que possui pneu reserva.",
                            style: TextStyle(color: corPrimaria, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  // 6. Detalhes do Serviço
                  Row(
                    children: [
                      const Icon(Icons.build_outlined, color: corPrimaria),
                      const SizedBox(width: 16.0),
                      const Text("Serviço", style: estiloSubtitulo),
                      const Spacer(),
                      const Text("Troca de Pneu", style: estiloValor),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  Row(
                    children: [
                      const Icon(Icons.money_outlined, color: corPrimaria),
                      const SizedBox(width: 16.0),
                      const Text("Valor Estimado", style: estiloSubtitulo),
                      const Spacer(),
                      Text(_valorEstimado, style: estiloValorPreco),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined, color: corPrimaria),
                      const SizedBox(width: 16.0),
                      const Text("Tempo de Chegada", style: estiloSubtitulo),
                      const Spacer(),
                      Text(_tempoChegada, style: estiloValor),
                    ],
                  ),
                  const SizedBox(height: 40.0),

                  // 7. Botão Confirmar
                  SizedBox(
                    width: double.infinity,
                    height: 56.0,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                        elevation: 0.0,
                      ),
                      child: const Text(
                        "Confirmar",
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}