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

$motoristaId = intval(
    $_GET["motorista_id"] ?? 0
);

if ($motoristaId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "motorista_id é obrigatório."
    ]);

    exit;
}

// Atendimentos concluídos pelo motorista, do mais recente ao mais antigo.
$stmt = $conn->prepare("
    SELECT
        s.id,
        s.tipo_reboque,
        s.forma_pagamento,
        s.endereco,
        s.valor_estimado,
        s.created_at,
        s.updated_at,

        c.nome AS cliente_nome

    FROM solicitacoes s

    INNER JOIN usuarios c
        ON c.id = s.cliente_id

    WHERE s.motorista_id = ?
      AND s.status = 'concluido'

    ORDER BY COALESCE(s.updated_at, s.created_at) DESC
");

$stmt->bind_param(
    "i",
    $motoristaId
);

$stmt->execute();

$resultado = $stmt->get_result();

$atendimentos = [];

$totalGeral = 0.0;
$totalMes = 0.0;

$mesAtual = date("Y-m");

while ($row = $resultado->fetch_assoc()) {
    $valor = floatval($row["valor_estimado"]);

    // Data de conclusão: última atualização da solicitação.
    $concluidoEm = $row["updated_at"] ?? $row["created_at"];

    $totalGeral += $valor;

    if (substr($concluidoEm, 0, 7) === $mesAtual) {
        $totalMes += $valor;
    }

    $atendimentos[] = [
        "id" => intval($row["id"]),
        "tipo_reboque" => $row["tipo_reboque"],
        "forma_pagamento" => $row["forma_pagamento"],
        "endereco" => $row["endereco"],
        "valor" => $valor,
        "concluido_em" => $concluidoEm,
        "cliente" => [
            "nome" => $row["cliente_nome"]
        ]
    ];
}

echo json_encode([
    "sucesso" => true,
    "resumo" => [
        "total_geral" => round($totalGeral, 2),
        "total_mes" => round($totalMes, 2),
        "quantidade" => count($atendimentos)
    ],
    "atendimentos" => $atendimentos
], JSON_UNESCAPED_UNICODE);
