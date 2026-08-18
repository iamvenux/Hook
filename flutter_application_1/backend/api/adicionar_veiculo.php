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

$usuarioId = intval(
    $dados["usuario_id"] ?? 0
);

$tipo = trim(
    $dados["tipo"] ?? ""
);

$marca = trim(
    $dados["marca"] ?? ""
);

$modelo = trim(
    $dados["modelo"] ?? ""
);

$ano = isset($dados["ano"])
    ? intval($dados["ano"])
    : null;

$placa = strtoupper(
    trim(
        $dados["placa"] ?? ""
    )
);

$cor = trim(
    $dados["cor"] ?? ""
);

// Remove hífen e espaço da placa.
$placa = str_replace(
    ["-", " "],
    "",
    $placa
);

// ============================================================
// VALIDAÇÕES
// ============================================================

if ($usuarioId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Usuário não identificado."
    ]);

    exit;
}

if (!in_array(
    $tipo,
    ["Carro", "Moto", "SUV"],
    true
)) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Tipo de veículo inválido."
    ]);

    exit;
}

if ($marca === "") {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe a marca do veículo."
    ]);

    exit;
}

if ($modelo === "") {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe o modelo do veículo."
    ]);

    exit;
}

if ($ano === null || $ano <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe um ano válido."
    ]);

    exit;
}

if ($placa === "") {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe a placa do veículo."
    ]);

    exit;
}

if ($cor === "") {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe a cor do veículo."
    ]);

    exit;
}

// ============================================================
// CONFIRMA QUE O USUÁRIO É CLIENTE
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
    $usuarioId
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
// VERIFICA PLACA DUPLICADA
// ============================================================

$stmt = $conn->prepare("
    SELECT id
    FROM veiculos
    WHERE placa = ?
    LIMIT 1
");

$stmt->bind_param(
    "s",
    $placa
);

$stmt->execute();

$resultado =
    $stmt->get_result();

if ($resultado->num_rows > 0) {
    http_response_code(409);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Já existe um veículo cadastrado com essa placa."
    ]);

    exit;
}

// ============================================================
// INSERE VEÍCULO
// ============================================================

$stmt = $conn->prepare("
    INSERT INTO veiculos (
        usuario_id,
        tipo,
        marca,
        modelo,
        ano,
        placa,
        cor
    )
    VALUES (?, ?, ?, ?, ?, ?, ?)
");

$stmt->bind_param(
    "isssiss",
    $usuarioId,
    $tipo,
    $marca,
    $modelo,
    $ano,
    $placa,
    $cor
);

if (!$stmt->execute()) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Erro ao cadastrar veículo.",
        "erro" => $stmt->error
    ]);

    exit;
}

$veiculoId =
    $conn->insert_id;

echo json_encode([
    "sucesso" => true,
    "mensagem" => "Veículo cadastrado com sucesso.",
    "veiculo" => [
        "id" => $veiculoId,
        "usuario_id" => $usuarioId,
        "tipo" => $tipo,
        "marca" => $marca,
        "modelo" => $modelo,
        "ano" => $ano,
        "placa" => $placa,
        "cor" => $cor
    ]
], JSON_UNESCAPED_UNICODE);