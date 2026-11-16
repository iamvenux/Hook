import 'package:flutter/material.dart';

import 'api_service.dart';

const Color _azul = Color(0xFF1A7EF5);
const Color _azulClaro = Color(0xFFE8F2FE);
const Color _preto = Color(0xFF1A1A1A);
const Color _cinzaTexto = Color(0xFF8A8A8A);
const Color _vermelho = Color(0xFFEF4444);
const Color _vermelhoClaro = Color(0xFFFDECEC);

/// Telefone só com dígitos -> (11) 99999-9999.
String formatarTelefone(String? bruto) {
  final d = (bruto ?? '').replaceAll(RegExp(r'\D'), '');

  if (d.length == 11) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
  }

  if (d.length == 10) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
  }

  return bruto ?? '';
}


/// Iniciais do nome (até 2 letras).
String iniciaisDoNome(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);

  if (partes.isEmpty) return '?';

  return partes.take(2).map((p) => p[0]).join().toUpperCase();
}

/// Avatar do usuário: mostra a foto quando existe; senão, as iniciais.
/// [fotoUrl] é o caminho vindo do servidor (ex.: uploads/perfil/u1_ab.jpg).
class AvatarUsuario extends StatelessWidget {
  final String nome;
  final String? fotoUrl;
  final double tamanho;

  /// null = círculo; senão, cantos arredondados com esse raio.
  final double? raio;
  final Color fundo;
  final Color corTexto;
  final Color? corBorda;

  const AvatarUsuario({
    super.key,
    required this.nome,
    this.fotoUrl,
    this.tamanho = 48,
    this.raio,
    this.fundo = _azulClaro,
    this.corTexto = _azul,
    this.corBorda,
  });

  @override
  Widget build(BuildContext context) {
    final url = ApiService.urlFoto(fotoUrl);

    final borda = raio == null
        ? BorderRadius.circular(tamanho / 2)
        : BorderRadius.circular(raio!);

    final iniciais = Container(
      width: tamanho,
      height: tamanho,
      color: fundo,
      alignment: Alignment.center,
      child: Text(
        iniciaisDoNome(nome),
        style: TextStyle(
          color: corTexto,
          fontSize: tamanho * 0.36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        borderRadius: borda,
        border: corBorda == null
            ? null
            : Border.all(color: corBorda!, width: 2),
      ),
      child: ClipRRect(
        borderRadius: borda,
        child: url == null
            ? iniciais
            : Image.network(
                url,
                width: tamanho,
                height: tamanho,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => iniciais,
                loadingBuilder: (context, child, progresso) =>
                    progresso == null ? child : iniciais,
              ),
      ),
    );
  }
}

/// Avatar grande + nome + contatos + botão "Editar perfil".
class PerfilCabecalho extends StatelessWidget {
  final String nome;
  final String? fotoUrl;
  final List<String> linhas;
  final VoidCallback onEditar;

  const PerfilCabecalho({
    super.key,
    required this.nome,
    this.fotoUrl,
    required this.linhas,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        AvatarUsuario(nome: nome, fotoUrl: fotoUrl, tamanho: 84),
        const SizedBox(height: 12),
        Text(
          nome,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _preto,
          ),
        ),
        const SizedBox(height: 4),
        for (final l in linhas.where((l) => l.trim().isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l,
              style: const TextStyle(fontSize: 14, color: _cinzaTexto),
            ),
          ),
        const SizedBox(height: 14),
        InkWell(
          onTap: onEditar,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _azulClaro,
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_outlined, size: 16, color: _azul),
                SizedBox(width: 6),
                Text(
                  'Editar perfil',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _azul,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

/// Linha da lista do perfil (ícone em quadrado + título + seta).
class PerfilOpcao extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final VoidCallback onTap;
  final bool perigo;

  const PerfilOpcao({
    super.key,
    required this.icone,
    required this.titulo,
    required this.onTap,
    this.perigo = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = perigo ? _vermelho : _azul;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: perigo ? _vermelhoClaro : _azulClaro,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, color: cor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: perigo ? _vermelho : _preto,
                ),
              ),
            ),
            if (!perigo)
              const Icon(
                Icons.chevron_right_rounded,
                color: _cinzaTexto,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
