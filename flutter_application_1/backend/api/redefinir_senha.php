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

$novaSenha =
    $dados["nova_senha"] ?? "";

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

if (strlen($novaSenha) < 6) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "A nova senha deve possuir pelo menos 6 caracteres."
    ]);

    exit;
}

$stmt = $conn->prepare("
    SELECT
        id,
        codigo_recuperacao_hash,
        codigo_recuperacao_expira
    FROM usuarios
    WHERE email = ?
      AND email_verificado = 1
    LIMIT 1
");

$stmt->bind_param(
    "s",
    $email
);

$stmt->execute();

$resultado = $stmt->get_result();

if ($resultado->num_rows === 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Código incorreto ou expirado."
    ]);

    exit;
}

$usuario = $resultado->fetch_assoc();

if (!codigoValido(
    $codigo,
    $usuario["codigo_recuperacao_hash"],
    $usuario["codigo_recuperacao_expira"]
)) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Código incorreto ou expirado."
    ]);

    exit;
}

$senhaHash = password_hash(
    $novaSenha,
    PASSWORD_DEFAULT
);

$usuarioId = intval(
    $usuario["id"]
);

$stmt = $conn->prepare("
    UPDATE usuarios
    SET
        senha_hash = ?,
        codigo_recuperacao_hash = NULL,
        codigo_recuperacao_expira = NULL
    WHERE id = ?
");

$stmt->bind_param(
    "si",
    $senhaHash,
    $usuarioId
);

$stmt->execute();

echo json_encode([
    "sucesso" => true,
    "mensagem" => "Senha alterada com sucesso."
], JSON_UNESCAPED_UNICODE);
