import 'package:flutter/material.dart';

import 'ajuda_suporte_screen.dart';
import 'api_service.dart';
import 'configuracoes_screen.dart';
import 'editar_perfil_screen.dart';
import 'enderecos_salvos_screen.dart';
import 'main.dart' show LoginScreen;
import 'perfil_componentes.dart';

/// Conteúdo da aba "Perfil" da home do cliente.
/// Usado dentro do Scaffold da HomeScreen (não tem AppBar/bottomNav próprios).
class PerfilClienteScreen extends StatefulWidget {
  const PerfilClienteScreen({super.key});

  @override
  State<PerfilClienteScreen> createState() =>
      _PerfilClienteScreenState();
}

class _PerfilClienteScreenState
    extends State<PerfilClienteScreen> {

  void _sair(BuildContext context) {
    ApiService.instance.logout();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _abrirEdicaoPerfil() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditarPerfilScreen(),
      ),
    );

    // Os getters de ApiService.instance já refletem os dados
    // novos; só precisamos reconstruir a tela pra exibi-los.
    if (mounted) {
      setState(() {});
    }
  }

  void _abrirEnderecosSalvos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EnderecosSalvosScreen(),
      ),
    );
  }

  void _abrirAjuda() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AjudaSuporteScreen(),
      ),
    );
  }

  void _abrirConfiguracoes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ConfiguracoesScreen(),
      ),
    );
  }

  void _emBreve(String recurso) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$recurso ainda não está disponível.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome = ApiService.instance.nomeUsuario?.trim();
    final email = ApiService.instance.emailUsuario ?? '';
    final telefone = formatarTelefone(ApiService.instance.telefoneUsuario);

    final nomeExibido =
        (nome == null || nome.isEmpty) ? 'Cliente Hook' : nome;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          PerfilCabecalho(
            nome: nomeExibido,
            fotoUrl: ApiService.instance.fotoUsuario,
            linhas: [email, telefone],
            onEditar: _abrirEdicaoPerfil,
          ),
          PerfilOpcao(
            icone: Icons.bookmark_border_rounded,
            titulo: 'Endereços salvos',
            onTap: _abrirEnderecosSalvos,
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
            onTap: () => _sair(context),
          ),
        ],
      ),
    );
  }
}
