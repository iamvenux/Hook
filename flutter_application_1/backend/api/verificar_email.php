<?php

header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . "/../cors.php";
require_once __DIR__ . "/../conexao.php";
require_once __DIR__ . "/../email_service.php";

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

$email = strtolower(
    trim(
        $dados["email"] ?? ""
    )
);

$codigo = trim(
    $dados["codigo"] ?? ""
);

if (
    !filter_var($email, FILTER_VALIDATE_EMAIL) ||
    !preg_match('/^\d{6}$/', $codigo)
) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "E-mail ou código inválido."
    ]);

    exit;
}

$stmt = $conn->prepare("
    SELECT
        id,
        email_verificado,
        codigo_verificacao_hash,
        codigo_verificacao_expira
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
    http_response_code(404);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Usuário não encontrado."
    ]);

    exit;
}

$usuario = $resultado->fetch_assoc();

if (intval($usuario["email_verificado"]) === 1) {
    echo json_encode([
        "sucesso" => true,
        "mensagem" => "E-mail já estava verificado."
    ], JSON_UNESCAPED_UNICODE);

    exit;
}

if (!codigoValido(
    $codigo,
    $usuario["codigo_verificacao_hash"],
    $usuario["codigo_verificacao_expira"]
)) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Código incorreto ou expirado."
    ]);

    exit;
}

$stmt = $conn->prepare("
    UPDATE usuarios
    SET
        email_verificado = 1,
        codigo_verificacao_hash = NULL,
        codigo_verificacao_expira = NULL
    WHERE id = ?
");

$usuarioId = intval(
    $usuario["id"]
);

$stmt->bind_param(
    "i",
    $usuarioId
);

$stmt->execute();

echo json_encode([
    "sucesso" => true,
    "mensagem" => "E-mail verificado com sucesso. Agora você já pode entrar."
], JSON_UNESCAPED_UNICODE);
