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
        usuario_id,
        tipo,
        marca,
        modelo,
        ano,
        placa,
        cor,
        padrao,
        ativo,
        created_at
    FROM veiculos
    WHERE usuario_id = ?
      AND ativo = 1
    ORDER BY padrao DESC, id DESC
");

$stmt->bind_param(
    "i",
    $usuarioId
);

$stmt->execute();

$resultado = $stmt->get_result();

$veiculos = [];

while ($row = $resultado->fetch_assoc()) {
    $veiculos[] = [
        "id" => intval($row["id"]),
        "usuario_id" => intval($row["usuario_id"]),
        "tipo" => $row["tipo"],
        "marca" => $row["marca"],
        "modelo" => $row["modelo"],
        "ano" => $row["ano"] !== null
            ? intval($row["ano"])
            : null,
        "placa" => $row["placa"],
        "cor" => $row["cor"],
        "padrao" => intval($row["padrao"]),
        "created_at" => $row["created_at"]
    ];
}

echo json_encode([
    "sucesso" => true,
    "veiculos" => $veiculos
], JSON_UNESCAPED_UNICODE);