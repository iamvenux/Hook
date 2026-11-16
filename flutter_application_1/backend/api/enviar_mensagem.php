<?php

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

$solicitacaoId =
    intval(
        $dados["solicitacao_id"] ?? 0
    );

$remetenteId =
    intval(
        $dados["remetente_id"] ?? 0
    );

$mensagem = trim(
    $dados["mensagem"] ?? ""
);

if (
    $solicitacaoId <= 0 ||
    $remetenteId <= 0 ||
    $mensagem === ""
) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Dados inválidos."
    ]);

    exit;
}

if (mb_strlen($mensagem) > 1000) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Mensagem muito longa."
    ]);

    exit;
}

$stmt = $conn->prepare("
    SELECT
        status
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
    $remetenteId,
    $remetenteId
);

$stmt->execute();

$resultado =
    $stmt->get_result();

if ($resultado->num_rows === 0) {
    http_response_code(403);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Você não participa desta solicitação."
    ]);

    exit;
}

$solicitacao =
    $resultado->fetch_assoc();

if (
    $solicitacao["status"] === "cancelado"
) {
    http_response_code(409);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Não é possível enviar mensagens em um resgate cancelado."
    ]);

    exit;
}

$stmt = $conn->prepare("
    INSERT INTO mensagens (
        solicitacao_id,
        remetente_id,
        mensagem
    )
    VALUES (?, ?, ?)
");

$stmt->bind_param(
    "iis",
    $solicitacaoId,
    $remetenteId,
    $mensagem
);

$stmt->execute();

echo json_encode([
    "sucesso" => true,
    "mensagem" => "Mensagem enviada."
], JSON_UNESCAPED_UNICODE);
