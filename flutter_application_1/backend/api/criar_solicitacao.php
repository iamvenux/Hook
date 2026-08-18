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

$clienteId = intval(
    $dados["cliente_id"] ?? 0
);

$veiculoId = intval(
    $dados["veiculo_id"] ?? 0
);

$tipoReboque = trim(
    $dados["tipo_reboque"] ?? ""
);

$formaPagamento = trim(
    $dados["forma_pagamento"] ?? ""
);

$endereco = trim(
    $dados["endereco"] ?? ""
);

$latitude =
    $dados["latitude"] ?? null;

$longitude =
    $dados["longitude"] ?? null;

$valorEstimado =
    $dados["valor_estimado"] ?? null;


/*
|--------------------------------------------------------------------------
| VALIDAÇÃO
|--------------------------------------------------------------------------
*/

if ($clienteId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "cliente_id inválido."
    ]);

    exit;
}

if ($veiculoId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "veiculo_id inválido."
    ]);

    exit;
}

if (
    $tipoReboque !== "Guincho Leve" &&
    $tipoReboque !== "Guincho Pesado"
) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Tipo de reboque inválido."
    ]);

    exit;
}

if (
    $formaPagamento !== "Pix" &&
    $formaPagamento !== "Dinheiro"
) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Forma de pagamento inválida."
    ]);

    exit;
}

if ($endereco === "") {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Endereço obrigatório."
    ]);

    exit;
}

if (
    $latitude === null ||
    $longitude === null
) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Latitude e longitude são obrigatórias."
    ]);

    exit;
}

$latitude = floatval($latitude);
$longitude = floatval($longitude);

if ($valorEstimado === null) {
    if ($tipoReboque === "Guincho Leve") {
        $valorEstimado = 350.00;
    } else {
        $valorEstimado = 550.00;
    }
}

$valorEstimado =
    floatval($valorEstimado);


/*
|--------------------------------------------------------------------------
| VERIFICA CLIENTE
|--------------------------------------------------------------------------
*/

$stmt = $conn->prepare("
    SELECT id
    FROM usuarios
    WHERE id = ?
      AND tipo = 'cliente'
    LIMIT 1
");

$stmt->bind_param(
    "i",
    $clienteId
);

$stmt->execute();

$resultado =
    $stmt->get_result();

if ($resultado->num_rows === 0) {
    http_response_code(404);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Cliente não encontrado."
    ]);

    exit;
}


/*
|--------------------------------------------------------------------------
| VERIFICA SE VEÍCULO PERTENCE AO CLIENTE
|--------------------------------------------------------------------------
*/

$stmt = $conn->prepare("
    SELECT id
    FROM veiculos
    WHERE id = ?
      AND usuario_id = ?
    LIMIT 1
");

$stmt->bind_param(
    "ii",
    $veiculoId,
    $clienteId
);

$stmt->execute();

$resultado =
    $stmt->get_result();

if ($resultado->num_rows === 0) {
    http_response_code(404);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Veículo não encontrado para este cliente."
    ]);

    exit;
}


/*
|--------------------------------------------------------------------------
| CRIA SOLICITAÇÃO
|--------------------------------------------------------------------------
*/

$sql = "
    INSERT INTO solicitacoes (
        cliente_id,
        motorista_id,
        veiculo_id,
        tipo_reboque,
        forma_pagamento,
        endereco,
        latitude,
        longitude,
        valor_estimado,
        status
    )
    VALUES (
        ?,
        NULL,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        'buscando'
    )
";

$stmt = $conn->prepare($sql);

if (!$stmt) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Erro ao preparar INSERT.",
        "erro" => $conn->error
    ]);

    exit;
}

$stmt->bind_param(
    "iisssddd",
    $clienteId,
    $veiculoId,
    $tipoReboque,
    $formaPagamento,
    $endereco,
    $latitude,
    $longitude,
    $valorEstimado
);

if (!$stmt->execute()) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Erro ao criar solicitação.",
        "erro" => $stmt->error
    ]);

    exit;
}

$solicitacaoId =
    $conn->insert_id;

echo json_encode([
    "sucesso" => true,
    "mensagem" => "Solicitação criada com sucesso.",
    "id" => $solicitacaoId,
    "solicitacao" => [
        "id" => $solicitacaoId,
        "cliente_id" => $clienteId,
        "veiculo_id" => $veiculoId,
        "tipo_reboque" => $tipoReboque,
        "forma_pagamento" => $formaPagamento,
        "endereco" => $endereco,
        "latitude" => $latitude,
        "longitude" => $longitude,
        "valor_estimado" => $valorEstimado,
        "status" => "buscando"
    ]
]);