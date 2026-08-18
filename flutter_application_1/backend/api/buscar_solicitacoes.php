<?php

header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . "/../conexao.php";

if ($_SERVER["REQUEST_METHOD"] !== "GET") {
    http_response_code(405);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Método não permitido."
    ]);

    exit;
}

$motoristaId = intval($_GET["motorista_id"] ?? 0);

if ($motoristaId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "motorista_id é obrigatório."
    ]);

    exit;
}

/*
|--------------------------------------------------------------------------
| VERIFICA SE O MOTORISTA EXISTE
|--------------------------------------------------------------------------
*/

$stmt = $conn->prepare("
    SELECT
        id,
        nome,
        disponivel,
        latitude_atual,
        longitude_atual
    FROM usuarios
    WHERE id = ?
      AND tipo = 'motorista'
    LIMIT 1
");

$stmt->bind_param("i", $motoristaId);
$stmt->execute();

$resultadoMotorista = $stmt->get_result();

if ($resultadoMotorista->num_rows === 0) {
    http_response_code(404);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Motorista não encontrado."
    ]);

    exit;
}

/*
|--------------------------------------------------------------------------
| BUSCA SOLICITAÇÕES DISPONÍVEIS
|--------------------------------------------------------------------------
*/

$sql = "
    SELECT
        s.id,
        s.cliente_id,
        s.veiculo_id,
        s.tipo_reboque,
        s.forma_pagamento,
        s.endereco,
        s.latitude,
        s.longitude,
        s.valor_estimado,
        s.status,
        s.created_at,

        u.nome AS cliente_nome,
        u.telefone AS cliente_telefone,

        v.tipo AS veiculo_tipo,
        v.marca AS veiculo_marca,
        v.modelo AS veiculo_modelo,
        v.ano AS veiculo_ano,
        v.placa AS veiculo_placa,
        v.cor AS veiculo_cor

    FROM solicitacoes s

    INNER JOIN usuarios u
        ON u.id = s.cliente_id

    INNER JOIN veiculos v
        ON v.id = s.veiculo_id

    WHERE s.status = 'buscando'
      AND s.motorista_id IS NULL

    ORDER BY s.created_at ASC
";

$resultado = $conn->query($sql);

if (!$resultado) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Erro ao buscar solicitações.",
        "erro" => $conn->error
    ]);

    exit;
}

$solicitacoes = [];

while ($row = $resultado->fetch_assoc()) {
    $solicitacoes[] = [
        "id" => intval($row["id"]),

        "cliente" => [
            "id" => intval($row["cliente_id"]),
            "nome" => $row["cliente_nome"],
            "telefone" => $row["cliente_telefone"]
        ],

        "veiculo" => [
            "id" => intval($row["veiculo_id"]),
            "tipo" => $row["veiculo_tipo"],
            "marca" => $row["veiculo_marca"],
            "modelo" => $row["veiculo_modelo"],
            "ano" => $row["veiculo_ano"] !== null
                ? intval($row["veiculo_ano"])
                : null,
            "placa" => $row["veiculo_placa"],
            "cor" => $row["veiculo_cor"]
        ],

        "tipo_reboque" => $row["tipo_reboque"],

        "forma_pagamento" => $row["forma_pagamento"],

        "endereco" => $row["endereco"],

        "latitude" => floatval($row["latitude"]),

        "longitude" => floatval($row["longitude"]),

        "valor_estimado" => floatval($row["valor_estimado"]),

        "status" => $row["status"],

        "created_at" => $row["created_at"]
    ];
}

echo json_encode([
    "sucesso" => true,
    "solicitacoes" => $solicitacoes
]);