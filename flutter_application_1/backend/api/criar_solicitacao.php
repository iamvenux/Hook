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

// ============================================================
// DADOS RECEBIDOS
// ============================================================

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

$precisaTroco = intval(
    $dados["precisa_troco"] ?? 0
);

$trocoPara = isset($dados["troco_para"])
    && $dados["troco_para"] !== null
        ? floatval($dados["troco_para"])
        : null;

$endereco = trim(
    $dados["endereco"] ?? ""
);

$latitude =
    $dados["latitude"] ?? null;

$longitude =
    $dados["longitude"] ?? null;

// valor_estimado NUNCA vem do cliente — é sempre calculado
// pelo servidor logo abaixo (ver bloco "PREÇO DINÂMICO").
// Isso evita que o app envie um preço manipulado.


// ============================================================
// VALIDAÇÃO
// ============================================================

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

// ============================================================
// VALIDAÇÃO DO TROCO
// ============================================================

// Se o pagamento não for dinheiro,
// nunca deve existir troco.
if ($formaPagamento !== "Dinheiro") {
    $precisaTroco = 0;
    $trocoPara = null;
}

// Normaliza para 0 ou 1.
$precisaTroco =
    $precisaTroco === 1
        ? 1
        : 0;

// Se escolheu dinheiro, mas NÃO precisa de troco,
// troco_para deve ficar NULL.
if (
    $formaPagamento === "Dinheiro" &&
    $precisaTroco === 0
) {
    $trocoPara = null;
}

// Se precisa de troco, o valor é obrigatório.
if (
    $formaPagamento === "Dinheiro" &&
    $precisaTroco === 1
) {
    if (
        $trocoPara === null ||
        $trocoPara <= 0
    ) {
        http_response_code(400);

        echo json_encode([
            "sucesso" => false,
            "mensagem" => "Informe para quanto precisa de troco."
        ]);

        exit;
    }
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

$latitude =
    floatval($latitude);

$longitude =
    floatval($longitude);


// ============================================================
// PREÇO DINÂMICO (base + por km até o motorista mais próximo)
// ============================================================
//
// Regra: valor = valor_base(tipo) + distancia_km * valor_por_km,
// com um piso mínimo por tipo (pra nunca cobrar menos que isso,
// mesmo se o motorista estiver muito perto).
//
// distancia_km = distância (Haversine) entre o ponto do cliente
// e o motorista DISPONÍVEL mais próximo no momento do pedido.
// Se nenhum motorista estiver disponível/com localização salva,
// usa uma distância padrão (fallback) pra não travar o pedido —
// o valor final é recalculado de qualquer forma quando um
// motorista realmente aceitar (ver aceitar_solicitacao.php).

function haversineKm(
    float $lat1,
    float $lon1,
    float $lat2,
    float $lon2
): float {
    $raioTerraKm = 6371.0;

    $dLat = deg2rad($lat2 - $lat1);
    $dLon = deg2rad($lon2 - $lon1);

    $a = sin($dLat / 2) ** 2
        + cos(deg2rad($lat1))
        * cos(deg2rad($lat2))
        * sin($dLon / 2) ** 2;

    $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

    return $raioTerraKm * $c;
}

const PRECOS_REBOQUE = [
    "Guincho Leve" => [
        "base"     => 80.00,
        "por_km"   => 3.50,
        "minimo"   => 150.00,
    ],
    "Guincho Pesado" => [
        "base"     => 150.00,
        "por_km"   => 5.50,
        "minimo"   => 280.00,
    ],
];

const DISTANCIA_PADRAO_KM = 12.0;

$config = PRECOS_REBOQUE[$tipoReboque];

// Busca motoristas online com localização salva.
$stmt = $conn->prepare("
    SELECT
        latitude_atual,
        longitude_atual
    FROM usuarios
    WHERE tipo = 'motorista'
      AND disponivel = 1
      AND latitude_atual IS NOT NULL
      AND longitude_atual IS NOT NULL
");

$stmt->execute();

$resultadoMotoristas =
    $stmt->get_result();

$menorDistanciaKm = null;

while ($m = $resultadoMotoristas->fetch_assoc()) {
    $distancia = haversineKm(
        $latitude,
        $longitude,
        floatval($m["latitude_atual"]),
        floatval($m["longitude_atual"])
    );

    if (
        $menorDistanciaKm === null ||
        $distancia < $menorDistanciaKm
    ) {
        $menorDistanciaKm = $distancia;
    }
}

$usouDistanciaPadrao = $menorDistanciaKm === null;

$distanciaKm =
    $menorDistanciaKm ?? DISTANCIA_PADRAO_KM;

$valorEstimado =
    $config["base"] + ($distanciaKm * $config["por_km"]);

if ($valorEstimado < $config["minimo"]) {
    $valorEstimado = $config["minimo"];
}

// Arredonda pra centavos.
$valorEstimado = round($valorEstimado, 2);


// ============================================================
// SE PEDIU TROCO, O VALOR PRECISA SER MAIOR QUE O SERVIÇO
// ============================================================

if (
    $formaPagamento === "Dinheiro" &&
    $precisaTroco === 1 &&
    $trocoPara <= $valorEstimado
) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "O valor para troco deve ser maior que o valor estimado do serviço."
    ]);

    exit;
}


// ============================================================
// VERIFICA CLIENTE
// ============================================================

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


// ============================================================
// VERIFICA SE VEÍCULO PERTENCE AO CLIENTE
// E SE ESTÁ ATIVO
// ============================================================

$stmt = $conn->prepare("
    SELECT id
    FROM veiculos
    WHERE id = ?
      AND usuario_id = ?
      AND ativo = 1
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


// ============================================================
// CRIA SOLICITAÇÃO
// ============================================================

$sql = "
    INSERT INTO solicitacoes (
        cliente_id,
        motorista_id,
        veiculo_id,
        tipo_reboque,
        forma_pagamento,
        precisa_troco,
        troco_para,
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
    "iissidsddd",
    $clienteId,
    $veiculoId,
    $tipoReboque,
    $formaPagamento,
    $precisaTroco,
    $trocoPara,
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


// ============================================================
// RESPOSTA
// ============================================================

echo json_encode([
    "sucesso" => true,
    "mensagem" => "Solicitação criada com sucesso.",
    "id" => $solicitacaoId,

    "solicitacao" => [
        "id" => $solicitacaoId,

        "cliente_id" =>
            $clienteId,

        "veiculo_id" =>
            $veiculoId,

        "tipo_reboque" =>
            $tipoReboque,

        "forma_pagamento" =>
            $formaPagamento,

        "precisa_troco" =>
            $precisaTroco,

        "troco_para" =>
            $trocoPara,

        "endereco" =>
            $endereco,

        "latitude" =>
            $latitude,

        "longitude" =>
            $longitude,

        "valor_estimado" =>
            $valorEstimado,

        "status" =>
            "buscando"
    ]
], JSON_UNESCAPED_UNICODE);