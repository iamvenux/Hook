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

$formaPagamento = trim(
    $dados["forma_pagamento"] ?? ""
);

if ($usuarioId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Usuário inválido."
    ]);

    exit;
}

if (!in_array(
    $formaPagamento,
    ["Pix", "Dinheiro"],
    true
)) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Forma de pagamento inválida."
    ]);

    exit;
}

$stmt = $conn->prepare("
    UPDATE usuarios
    SET forma_pagamento_padrao = ?
    WHERE id = ?
");

$stmt->bind_param(
    "si",
    $formaPagamento,
    $usuarioId
);

if (!$stmt->execute()) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Erro ao salvar a forma de pagamento."
    ]);

    exit;
}

echo json_encode([
    "sucesso" => true,
    "mensagem" => "Forma de pagamento padrão atualizada.",
    "forma_pagamento" => $formaPagamento
], JSON_UNESCAPED_UNICODE);
