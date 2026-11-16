import 'package:flutter/material.dart';

import 'ajuda_suporte_screen.dart';
import 'api_service.dart';
import 'configuracoes_screen.dart';
import 'editar_perfil_screen.dart';
import 'main.dart' show LoginScreen;
import 'perfil_componentes.dart';

/// Conteúdo da aba "Perfil" da home do motorista/socorrista.
/// Usado dentro do Scaffold da HomeSocorristaScreen (não tem bottomNav próprio).
class PerfilSocorristaScreen extends StatefulWidget {
  final String nome;
  final String tipoAtuacao;

  const PerfilSocorristaScreen({
    super.key,
    required this.nome,
    required this.tipoAtuacao,
  });

  @override
  State<PerfilSocorristaScreen> createState() =>
      _PerfilSocorristaScreenState();
}

class _PerfilSocorristaScreenState extends State<PerfilSocorristaScreen> {
  void _sair() {
    ApiService.instance.logout();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _abrirEdicaoPerfil() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditarPerfilScreen()),
    );

    // ApiService já guarda os dados novos; só reconstrói a tela.
    if (mounted) setState(() {});
  }

  void _abrirAjuda() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AjudaSuporteScreen(motorista: true),
      ),
    );
  }

  void _abrirConfiguracoes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()),
    );
  }

  void _emBreve(String recurso) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$recurso ainda não está disponível.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = ApiService.instance;
    final nomeApi = api.nomeUsuario?.trim();
    final nome = (nomeApi == null || nomeApi.isEmpty) ? widget.nome : nomeApi;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          PerfilCabecalho(
            nome: nome,
            fotoUrl: ApiService.instance.fotoUsuario,
            linhas: [
              widget.tipoAtuacao,
              api.emailUsuario ?? '',
              formatarTelefone(api.telefoneUsuario),
            ],
            onEditar: _abrirEdicaoPerfil,
          ),
          PerfilOpcao(
            icone: Icons.person_outline_rounded,
            titulo: 'Meus dados',
            onTap: _abrirEdicaoPerfil,
          ),
          PerfilOpcao(
            icone: Icons.description_outlined,
            titulo: 'Documentos (em breve)',
            onTap: () => _emBreve('Documentos'),
          ),
          PerfilOpcao(
            icone: Icons.help_outline_rounded,
            titulo: 'Ajuda e suporte',
            onTap: _abrirAjuda,
          ),
          PerfilOpcao(
            icone: Icons.settings_outlined,
            titulo: 'Configurações',
            onTap: _abrirConfiguracoes,
          ),
          PerfilOpcao(
            icone: Icons.logout_rounded,
            titulo: 'Sair',
            perigo: true,
            onTap: _sair,
          ),
        ],
      ),
    );
  }
}
