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

$usuarioId = intval(
    $_GET["usuario_id"] ?? 0
);

if ($usuarioId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "usuario_id é obrigatório."
    ]);

    exit;
}

$stmt = $conn->prepare("
    SELECT
        id,
        apelido,
        endereco,
        latitude,
        longitude,
        created_at
    FROM enderecos
    WHERE usuario_id = ?
    ORDER BY apelido ASC, id ASC
");

$stmt->bind_param(
    "i",
    $usuarioId
);

$stmt->execute();

$resultado = $stmt->get_result();

$enderecos = [];

while ($row = $resultado->fetch_assoc()) {
    $enderecos[] = [
        "id" => intval($row["id"]),
        "apelido" => $row["apelido"],
        "endereco" => $row["endereco"],
        "latitude" => floatval($row["latitude"]),
        "longitude" => floatval($row["longitude"]),
        "created_at" => $row["created_at"]
    ];
}

echo json_encode([
    "sucesso" => true,
    "enderecos" => $enderecos
], JSON_UNESCAPED_UNICODE);
