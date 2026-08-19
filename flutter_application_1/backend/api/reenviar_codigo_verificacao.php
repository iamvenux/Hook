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

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe um e-mail válido."
    ]);

    exit;
}

$stmt = $conn->prepare("
    SELECT
        id,
        nome,
        email_verificado
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
        "mensagem" => "Cadastro não encontrado."
    ]);

    exit;
}

$usuario = $resultado->fetch_assoc();

if (intval($usuario["email_verificado"]) === 1) {
    http_response_code(409);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Este e-mail já está verificado."
    ]);

    exit;
}

$codigo = gerarCodigo6Digitos();
$codigoHash = criarHashCodigo($codigo);

$expira = date(
    "Y-m-d H:i:s",
    time() + 600
);

$stmt = $conn->prepare("
    UPDATE usuarios
    SET
        codigo_verificacao_hash = ?,
        codigo_verificacao_expira = ?
    WHERE id = ?
");

$usuarioId = intval(
    $usuario["id"]
);

$stmt->bind_param(
    "ssi",
    $codigoHash,
    $expira,
    $usuarioId
);

$stmt->execute();

try {
    $html = htmlCodigo(
        $usuario["nome"],
        $codigo,
        "Este é seu novo código para confirmar o e-mail."
    );

    enviarEmailHook(
        $email,
        $usuario["nome"],
        "Novo código de verificação - Hook",
        $html,
        "Seu novo código de verificação do Hook é: {$codigo}. Ele expira em 10 minutos."
    );

    echo json_encode([
        "sucesso" => true,
        "mensagem" => "Um novo código foi enviado."
    ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Não foi possível enviar o código.",
        "erro" => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
