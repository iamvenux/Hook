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

/*
|--------------------------------------------------------------------------
| RESPOSTA GENÉRICA
|--------------------------------------------------------------------------
|
| Não informamos se o e-mail existe ou não.
|
*/

$resposta = [
    "sucesso" => true,
    "mensagem" => "Se existir uma conta verificada com este e-mail, enviaremos um código de recuperação."
];

if ($resultado->num_rows === 0) {
    echo json_encode(
        $resposta,
        JSON_UNESCAPED_UNICODE
    );

    exit;
}

$usuario = $resultado->fetch_assoc();

if (intval($usuario["email_verificado"]) !== 1) {
    echo json_encode(
        $resposta,
        JSON_UNESCAPED_UNICODE
    );

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
        codigo_recuperacao_hash = ?,
        codigo_recuperacao_expira = ?
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
        "Use este código para redefinir sua senha."
    );

    enviarEmailHook(
        $email,
        $usuario["nome"],
        "Recuperação de senha - Hook",
        $html,
        "Seu código para redefinir a senha do Hook é: {$codigo}. Ele expira em 10 minutos."
    );

    echo json_encode(
        $resposta,
        JSON_UNESCAPED_UNICODE
    );

} catch (Throwable $e) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Não foi possível enviar o e-mail de recuperação.",
        "erro" => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
