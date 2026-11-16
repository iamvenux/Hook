<?php

header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . "/../cors.php";
require_once __DIR__ . "/../conexao.php";

if ($_SERVER["REQUEST_METHOD"] !== "GET") {
    http_response_code(405);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Método não permitido."
    ]);

    exit;
}

$solicitacaoId = intval(
    $_GET["solicitacao_id"] ?? 0
);

$usuarioId = intval(
    $_GET["usuario_id"] ?? 0
);

if ($solicitacaoId <= 0 || $usuarioId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "solicitacao_id e usuario_id são obrigatórios."
    ]);

    exit;
}

// Confere se o usuário participa desta solicitação
// (mesma regra usada em enviar_mensagem.php).
$stmt = $conn->prepare("
    SELECT id
    FROM solicitacoes
    WHERE id = ?
      AND (
        cliente_id = ?
        OR motorista_id = ?
      )
    LIMIT 1
");

$stmt->bind_param(
    "iii",
    $solicitacaoId,
    $usuarioId,
    $usuarioId
);

$stmt->execute();

$resultado = $stmt->get_result();

if ($resultado->num_rows === 0) {
    http_response_code(403);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Você não participa desta solicitação."
    ]);

    exit;
}

$stmt = $conn->prepare("
    SELECT
        id,
        solicitacao_id,
        remetente_id,
        mensagem,
        created_at
    FROM mensagens
    WHERE solicitacao_id = ?
    ORDER BY id ASC
");

$stmt->bind_param(
    "i",
    $solicitacaoId
);

$stmt->execute();

$resultado = $stmt->get_result();

$mensagens = [];

while ($row = $resultado->fetch_assoc()) {
    $mensagens[] = [
        "id" => intval($row["id"]),
        "solicitacao_id" => intval($row["solicitacao_id"]),
        "remetente_id" => intval($row["remetente_id"]),
        "mensagem" => $row["mensagem"],
        "created_at" => $row["created_at"]
    ];
}

echo json_encode([
    "sucesso" => true,
    "mensagens" => $mensagens
], JSON_UNESCAPED_UNICODE);
