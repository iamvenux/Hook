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

// ============================================================
// CONFIRMA CLIENTE
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
// BUSCA VEÍCULOS
// ============================================================

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
        created_at
    FROM veiculos
    WHERE usuario_id = ?
    ORDER BY id DESC
");

$stmt->bind_param(
    "i",
    $usuarioId
);

$stmt->execute();

$resultado =
    $stmt->get_result();

$veiculos = [];

while (
    $row = $resultado->fetch_assoc()
) {
    $veiculos[] = [
        "id" => intval(
            $row["id"]
        ),

        "usuario_id" => intval(
            $row["usuario_id"]
        ),

        "tipo" => $row["tipo"],

        "marca" => $row["marca"],

        "modelo" => $row["modelo"],

        "ano" => $row["ano"] !== null
            ? intval($row["ano"])
            : null,

        "placa" => $row["placa"],

        "cor" => $row["cor"],

        "created_at" => $row["created_at"]
    ];
}

echo json_encode([
    "sucesso" => true,
    "veiculos" => $veiculos
], JSON_UNESCAPED_UNICODE);