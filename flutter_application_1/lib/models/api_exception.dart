/// Erro retornado pela API (ou gerado ao validar uma resposta dela).
class ApiException implements Exception {
  final String mensagem;
  final int? statusCode;

  ApiException(
    this.mensagem, {
    this.statusCode,
  });

  @override
  String toString() => mensagem;
}
