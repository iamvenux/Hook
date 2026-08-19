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

if ($solicitacaoId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "solicitacao_id é obrigatório."
    ]);

    exit;
}

$sql = "
    SELECT
        s.id,
        s.cliente_id,
        s.motorista_id,
        s.veiculo_id,
        s.tipo_reboque,
        s.forma_pagamento,
        s.endereco,
        s.latitude,
        s.longitude,
        s.valor_estimado,
        s.status,
        s.created_at,
        s.updated_at,

        u.nome AS motorista_nome,
        u.telefone AS motorista_telefone,
        u.placa_guincho AS motorista_placa,
        u.latitude_atual AS motorista_latitude,
        u.longitude_atual AS motorista_longitude

    FROM solicitacoes s

    LEFT JOIN usuarios u
        ON u.id = s.motorista_id

    WHERE s.id = ?

    LIMIT 1
";

$stmt = $conn->prepare($sql);

if (!$stmt) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Erro ao preparar consulta.",
        "erro" => $conn->error
    ]);

    exit;
}

$stmt->bind_param(
    "i",
    $solicitacaoId
);

$stmt->execute();

$resultado = $stmt->get_result();

if ($resultado->num_rows === 0) {
    http_response_code(404);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Solicitação não encontrada."
    ]);

    exit;
}

$s = $resultado->fetch_assoc();

$mensagem = "Procurando o guincho mais próximo...";

switch ($s["status"]) {
    case "aceito":
        $mensagem = "Guincho encontrado! O motorista aceitou sua solicitação.";
        break;

    case "a_caminho":
        $mensagem = "O guincho está a caminho.";
        break;

    case "concluido":
        $mensagem = "Serviço concluído!";
        break;

    case "cancelado":
        $mensagem = "Solicitação cancelada.";
        break;
}

$motorista = null;

if ($s["motorista_id"] !== null) {
    $motorista = [
        "id" => intval($s["motorista_id"]),
        "nome" => $s["motorista_nome"],
        "telefone" => $s["motorista_telefone"],
        "placa" => $s["motorista_placa"],
        "latitude" => $s["motorista_latitude"] !== null
            ? floatval($s["motorista_latitude"])
            : null,
        "longitude" => $s["motorista_longitude"] !== null
            ? floatval($s["motorista_longitude"])
            : null
    ];
}

echo json_encode([
    "sucesso" => true,

    "mensagem" => $mensagem,

    "solicitacao" => [
        "id" => intval($s["id"]),
        "cliente_id" => intval($s["cliente_id"]),
        "motorista_id" => $s["motorista_id"] !== null
            ? intval($s["motorista_id"])
            : null,
        "veiculo_id" => intval($s["veiculo_id"]),
        "tipo_reboque" => $s["tipo_reboque"],
        "forma_pagamento" => $s["forma_pagamento"],
        "endereco" => $s["endereco"],
        "latitude" => floatval($s["latitude"]),
        "longitude" => floatval($s["longitude"]),
        "valor_estimado" => floatval($s["valor_estimado"]),
        "status" => $s["status"],
        "created_at" => $s["created_at"],
        "updated_at" => $s["updated_at"]
    ],

    "motorista" => $motorista
]);