import 'package:flutter/material.dart';

enum CategoriaServico { reboque, ajuda }

class ServicoConfig {
  final CategoriaServico categoria;
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final String valorEstimado;
  final bool exigeDescricao;

  const ServicoConfig({
    required this.categoria,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.valorEstimado,
    this.exigeDescricao = false,
  });

  bool get isReboque => categoria == CategoriaServico.reboque;

  String get tituloResumo =>
      isReboque ? 'RESUMO DO SERVIÇO' : 'SOLICITAR AJUDA';

  String get labelBotaoResumo =>
      isReboque ? 'Solicitar guincho' : 'Solicitar Ajuda';

  String get labelProfissional =>
      isReboque ? 'guincho' : 'socorrista';
}

const Map<String, ServicoConfig> tiposDeReboque = {
  'Guincho Leve': ServicoConfig(
    categoria: CategoriaServico.reboque,
    titulo: 'Guincho Leve',
    subtitulo: 'Até 3.5 toneladas',
    icone: Icons.local_shipping_rounded,
    valorEstimado: 'R\$ 350,00',
  ),
  'Guincho Pesado': ServicoConfig(
    categoria: CategoriaServico.reboque,
    titulo: 'Guincho Pesado',
    subtitulo: 'Caminhões e ônibus',
    icone: Icons.rv_hookup_rounded,
    valorEstimado: 'R\$ 550,00',
  ),
};

const Map<String, ServicoConfig> tiposDeAjuda = {
  'Pneu Furado': ServicoConfig(
    categoria: CategoriaServico.ajuda,
    titulo: 'Pneu Furado',
    subtitulo: 'Troca ou reparo emergencial',
    icone: Icons.tire_repair_rounded,
    valorEstimado: 'R\$ 120,00',
  ),
  'Falta de Combustível': ServicoConfig(
    categoria: CategoriaServico.ajuda,
    titulo: 'Falta de Combustível',
    subtitulo: 'Auxílio para pane seca',
    icone: Icons.local_gas_station_rounded,
    valorEstimado: 'R\$ 90,00',
  ),
  'Bateria Descarregada': ServicoConfig(
    categoria: CategoriaServico.ajuda,
    titulo: 'Bateria Descarregada',
    subtitulo: 'Carga auxiliar e diagnóstico rápido',
    icone: Icons.battery_charging_full_rounded,
    valorEstimado: 'R\$ 100,00',
  ),
  'Outros': ServicoConfig(
    categoria: CategoriaServico.ajuda,
    titulo: 'Outros',
    subtitulo: 'Descreva a ajuda necessária',
    icone: Icons.build_rounded,
    valorEstimado: 'A combinar',
    exigeDescricao: true,
  ),
};
