<?php

header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . "/../cors.php";
require_once __DIR__ . "/../conexao.php";

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    http_response_code(405);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Método não permitido."
    ]);

    exit;
}

$dados = json_decode(
    file_get_contents("php://input"),
    true
);

if (!is_array($dados)) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "JSON inválido."
    ]);

    exit;
}

$usuarioId = intval(
    $dados["usuario_id"] ?? 0
);

$enderecoId = intval(
    $dados["endereco_id"] ?? 0
);

if ($usuarioId <= 0 || $enderecoId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Dados inválidos."
    ]);

    exit;
}

// Só apaga se o endereço for do próprio usuário.
$stmt = $conn->prepare("
    DELETE FROM enderecos
    WHERE id = ?
      AND usuario_id = ?
");

$stmt->bind_param(
    "ii",
    $enderecoId,
    $usuarioId
);

if (!$stmt->execute()) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Erro ao excluir o endereço."
    ]);

    exit;
}

if ($stmt->affected_rows === 0) {
    http_response_code(404);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Endereço não encontrado."
    ]);

    exit;
}

echo json_encode([
    "sucesso" => true,
    "mensagem" => "Endereço excluído."
], JSON_UNESCAPED_UNICODE);
