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

$email = strtolower(
    trim(
        $dados["email"] ?? ""
    )
);

$senha =
    $dados["senha"] ?? "";

if (
    !filter_var($email, FILTER_VALIDATE_EMAIL) ||
    $senha === ""
) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe e-mail e senha."
    ]);

    exit;
}

$stmt = $conn->prepare("
    SELECT
        id,
        nome,
        email,
        email_verificado,
        senha_hash,
        tipo,
        telefone,
        placa_guincho,
        disponivel,
        api_token
    FROM usuarios
    WHERE email = ?
    LIMIT 1
");

$stmt->bind_param(
    "s",
    $email
);

$stmt->execute();

$resultado = $stmt->get_result();

if ($resultado->num_rows === 0) {
    http_response_code(401);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Email ou senha incorretos."
    ]);

    exit;
}

$usuario = $resultado->fetch_assoc();

if (!password_verify(
    $senha,
    $usuario["senha_hash"]
)) {
    http_response_code(401);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Email ou senha incorretos."
    ]);

    exit;
}

if (
    $usuario["tipo"] === "cliente" &&
    intval($usuario["email_verificado"]) !== 1
) {
    http_response_code(403);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Confirme seu e-mail antes de entrar.",
        "requer_verificacao" => true,
        "email" => $usuario["email"]
    ], JSON_UNESCAPED_UNICODE);

    exit;
}

echo json_encode([
    "sucesso" => true,
    "mensagem" => "Login realizado com sucesso.",
    "usuario" => [
        "id" => intval($usuario["id"]),
        "nome" => $usuario["nome"],
        "email" => $usuario["email"],
        "tipo" => $usuario["tipo"],
        "telefone" => $usuario["telefone"],
        "placa_guincho" => $usuario["placa_guincho"],
        "disponivel" => intval($usuario["disponivel"]),
        "api_token" => $usuario["api_token"]
    ]
], JSON_UNESCAPED_UNICODE);
