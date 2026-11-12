import 'package:flutter/services.dart';

// ============================================================
// MÁSCARA DE TELEFONE
// (00) 00000-0000
// ============================================================

class TelefoneInputFormatter extends TextInputFormatter {
  /// Formata um telefone (com ou sem máscara) como `(00) 00000-0000`.
  /// Aceita texto parcial, então serve tanto para digitação quanto
  /// para exibir um número já salvo.
  static String formatar(String valor) {
    var numeros = valor.replaceAll(RegExp(r'\D'), '');

    if (numeros.length > 11) {
      numeros = numeros.substring(0, 11);
    }

    String texto = '';

    if (numeros.isNotEmpty) {
      final fimDdd = numeros.length < 2 ? numeros.length : 2;
      texto = '(${numeros.substring(0, fimDdd)}';
    }

    if (numeros.length >= 2) {
      texto += ') ';
    }

    if (numeros.length > 2) {
      final fimNumero = numeros.length < 7 ? numeros.length : 7;
      texto += numeros.substring(2, fimNumero);
    }

    if (numeros.length > 7) {
      texto += '-${numeros.substring(7)}';
    }

    return texto;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = formatar(newValue.text);

    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
