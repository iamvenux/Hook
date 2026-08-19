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

$clienteId = intval(
    $_GET["cliente_id"] ?? 0
);

if ($clienteId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "cliente_id é obrigatório."
    ]);

    exit;
}

$stmt = $conn->prepare("
    SELECT
        s.id,
        s.tipo_reboque,
        s.forma_pagamento,
        s.endereco,
        s.valor_estimado,
        s.status,
        s.created_at,

        v.id AS veiculo_id,
        v.tipo AS veiculo_tipo,
        v.marca,
        v.modelo,
        v.placa,
        v.cor,

        m.id AS motorista_id,
        m.nome AS motorista_nome,
        m.telefone AS motorista_telefone,
        m.placa_guincho

    FROM solicitacoes s

    INNER JOIN veiculos v
        ON v.id = s.veiculo_id

    LEFT JOIN usuarios m
        ON m.id = s.motorista_id

    WHERE s.cliente_id = ?

    ORDER BY s.created_at DESC
");

$stmt->bind_param(
    "i",
    $clienteId
);

$stmt->execute();

$resultado = $stmt->get_result();

$historico = [];

while ($row = $resultado->fetch_assoc()) {
    $historico[] = [
        "id" => intval($row["id"]),
        "tipo_reboque" => $row["tipo_reboque"],
        "forma_pagamento" => $row["forma_pagamento"],
        "endereco" => $row["endereco"],
        "valor_estimado" => floatval($row["valor_estimado"]),
        "status" => $row["status"],
        "created_at" => $row["created_at"],

        "veiculo" => [
            "id" => intval($row["veiculo_id"]),
            "tipo" => $row["veiculo_tipo"],
            "marca" => $row["marca"],
            "modelo" => $row["modelo"],
            "placa" => $row["placa"],
            "cor" => $row["cor"]
        ],

        "motorista" => $row["motorista_id"] !== null
            ? [
                "id" => intval($row["motorista_id"]),
                "nome" => $row["motorista_nome"],
                "telefone" => $row["motorista_telefone"],
                "placa" => $row["placa_guincho"]
            ]
            : null
    ];
}

echo json_encode([
    "sucesso" => true,
    "historico" => $historico
], JSON_UNESCAPED_UNICODE);