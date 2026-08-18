<?php

$host = "localhost";
$usuario = "root";
$senha = "";
$banco = "hook_db";
$porta = 3306;

$conn = new mysqli(
    $host,
    $usuario,
    $senha,
    $banco,
    $porta
);

if ($conn->connect_error) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Erro ao conectar com o banco de dados.",
        "erro" => $conn->connect_error
    ]);

    exit;
}

$conn->set_charset("utf8mb4");