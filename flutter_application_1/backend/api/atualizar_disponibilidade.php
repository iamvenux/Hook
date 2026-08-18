<?php

header("Content-Type: application/json; charset=UTF-8");

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

$motoristaId = intval(
    $dados["motorista_id"] ?? 0
);

$disponivel = intval(
    $dados["disponivel"] ?? -1
);

if ($motoristaId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "motorista_id é obrigatório."
    ]);

    exit;
}

if ($disponivel !== 0 && $disponivel !== 1) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "disponivel deve ser 0 ou 1."
    ]);

    exit;
}

/*
|--------------------------------------------------------------------------
| Verifica se o motorista existe
|--------------------------------------------------------------------------
*/

$stmt = $conn->prepare("
    SELECT id
    FROM usuarios
    WHERE id = ?
      AND tipo = 'motorista'
    LIMIT 1
");

$stmt->bind_param(
    "i",
    $motoristaId
);

$stmt->execute();

$resultado =
    $stmt->get_result();

if ($resultado->num_rows === 0) {
    http_response_code(404);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Motorista não encontrado."
    ]);

    exit;
}

/*
|--------------------------------------------------------------------------
| Atualiza disponibilidade
|--------------------------------------------------------------------------
*/

$stmt = $conn->prepare("
    UPDATE usuarios
    SET disponivel = ?
    WHERE id = ?
      AND tipo = 'motorista'
");

$stmt->bind_param(
    "ii",
    $disponivel,
    $motoristaId
);

if (!$stmt->execute()) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Erro ao atualizar disponibilidade.",
        "erro" => $stmt->error
    ]);

    exit;
}

echo json_encode([
    "sucesso" => true,
    "mensagem" => $disponivel === 1
        ? "Motorista ficou online."
        : "Motorista ficou offline.",
    "motorista_id" => $motoristaId,
    "disponivel" => $disponivel
]);