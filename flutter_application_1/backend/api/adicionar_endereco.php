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

$usuarioId = intval(
    $dados["usuario_id"] ?? 0
);

$apelido = trim(
    $dados["apelido"] ?? ""
);

$endereco = trim(
    $dados["endereco"] ?? ""
);

$latitude = $dados["latitude"] ?? null;
$longitude = $dados["longitude"] ?? null;

/*
|--------------------------------------------------------------------------
| VALIDAÇÕES
|--------------------------------------------------------------------------
*/

if ($usuarioId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Usuário inválido."
    ]);

    exit;
}

if ($apelido === "" || mb_strlen($apelido) > 40) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Dê um nome ao endereço (até 40 caracteres)."
    ]);

    exit;
}

if ($endereco === "" || mb_strlen($endereco) > 255) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe o endereço."
    ]);

    exit;
}

if (
    !is_numeric($latitude) ||
    !is_numeric($longitude) ||
    $latitude < -90 || $latitude > 90 ||
    $longitude < -180 || $longitude > 180
) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Coordenadas inválidas."
    ]);

    exit;
}

$latitude = floatval($latitude);
$longitude = floatval($longitude);

// Limite por usuário, para a lista não crescer sem controle.
$stmt = $conn->prepare("
    SELECT COUNT(*) AS total
    FROM enderecos
    WHERE usuario_id = ?
");

$stmt->bind_param(
    "i",
    $usuarioId
);

$stmt->execute();

$total = intval(
    $stmt->get_result()->fetch_assoc()["total"]
);

if ($total >= 10) {
    http_response_code(409);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Você pode salvar até 10 endereços."
    ]);

    exit;
}

/*
|--------------------------------------------------------------------------
| INSERE
|--------------------------------------------------------------------------
*/

$stmt = $conn->prepare("
    INSERT INTO enderecos (
        usuario_id,
        apelido,
        endereco,
        latitude,
        longitude
    )
    VALUES (?, ?, ?, ?, ?)
");

$stmt->bind_param(
    "issdd",
    $usuarioId,
    $apelido,
    $endereco,
    $latitude,
    $longitude
);

if (!$stmt->execute()) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Erro ao salvar o endereço."
    ]);

    exit;
}

echo json_encode([
    "sucesso" => true,
    "mensagem" => "Endereço salvo com sucesso.",
    "endereco" => [
        "id" => intval($conn->insert_id),
        "apelido" => $apelido,
        "endereco" => $endereco,
        "latitude" => $latitude,
        "longitude" => $longitude
    ]
], JSON_UNESCAPED_UNICODE);
