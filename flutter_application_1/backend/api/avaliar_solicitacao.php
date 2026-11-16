<?php

header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . "/../cors.php";
require_once __DIR__ . "/../conexao.php";

function responder($codigo, $sucesso, $mensagem, $extra = []) {
    http_response_code($codigo);

    echo json_encode(
        array_merge(
            ["sucesso" => $sucesso, "mensagem" => $mensagem],
            $extra
        ),
        JSON_UNESCAPED_UNICODE
    );

    exit;
}

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    responder(405, false, "Método não permitido.");
}

$dados = json_decode(file_get_contents("php://input"), true);

if (!is_array($dados)) {
    responder(400, false, "JSON inválido.");
}

$solicitacaoId = intval($dados["solicitacao_id"] ?? 0);
$avaliadorId   = intval($dados["usuario_id"] ?? 0);
$nota          = intval($dados["nota"] ?? 0);
$comentario    = trim((string)($dados["comentario"] ?? ""));

if ($solicitacaoId <= 0 || $avaliadorId <= 0) {
    responder(400, false, "Dados inválidos.");
}

if ($nota < 1 || $nota > 5) {
    responder(400, false, "A nota deve ser de 1 a 5.");
}

if (mb_strlen($comentario) > 300) {
    responder(400, false, "O comentário pode ter no máximo 300 caracteres.");
}

// Tabela própria: uma avaliação por pessoa em cada atendimento
// (cliente avalia o motorista e o motorista avalia o cliente).
$conn->query(
    "CREATE TABLE IF NOT EXISTS avaliacoes_atendimento (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        solicitacao_id INT UNSIGNED NOT NULL,
        avaliador_id INT UNSIGNED NOT NULL,
        avaliado_id INT UNSIGNED NOT NULL,
        nota TINYINT UNSIGNED NOT NULL,
        comentario VARCHAR(300) NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_avaliador (solicitacao_id, avaliador_id)
    ) ENGINE=InnoDB"
);

$stmt = $conn->prepare(
    "SELECT cliente_id, motorista_id, status
       FROM solicitacoes WHERE id = ? LIMIT 1"
);

$stmt->bind_param("i", $solicitacaoId);
$stmt->execute();

$sol = $stmt->get_result()->fetch_assoc();

if (!$sol) {
    responder(404, false, "Solicitação não encontrada.");
}

if ($sol["status"] !== "concluido") {
    responder(409, false, "Só é possível avaliar atendimentos concluídos.");
}

$clienteId   = intval($sol["cliente_id"]);
$motoristaId = intval($sol["motorista_id"]);

if ($avaliadorId === $clienteId) {
    $avaliadoId = $motoristaId;
} elseif ($avaliadorId === $motoristaId) {
    $avaliadoId = $clienteId;
} else {
    responder(403, false, "Você não participou deste atendimento.");
}

if ($avaliadoId <= 0) {
    responder(409, false, "Atendimento sem outra parte para avaliar.");
}

$stmt = $conn->prepare(
    "INSERT INTO avaliacoes_atendimento
        (solicitacao_id, avaliador_id, avaliado_id, nota, comentario)
     VALUES (?, ?, ?, ?, ?)"
);

$comentarioBanco = $comentario === "" ? null : $comentario;

$stmt->bind_param(
    "iiiis",
    $solicitacaoId,
    $avaliadorId,
    $avaliadoId,
    $nota,
    $comentarioBanco
);

if (!$stmt->execute()) {
    if ($conn->errno === 1062) {
        responder(409, false, "Você já avaliou este atendimento.");
    }

    error_log("avaliar_solicitacao: " . $stmt->error);

    responder(500, false, "Erro ao salvar a avaliação.");
}

responder(200, true, "Avaliação enviada. Obrigado!");
