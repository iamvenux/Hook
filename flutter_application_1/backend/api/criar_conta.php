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

if (!is_array($dados)) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "JSON inválido."
    ]);

    exit;
}

$nome = trim(
    $dados["nome"] ?? ""
);

$email = strtolower(
    trim(
        $dados["email"] ?? ""
    )
);

$senha = $dados["senha"] ?? "";

$telefone = preg_replace(
    '/\D/',
    '',
    $dados["telefone"] ?? ""
);

$tipo = trim(
    $dados["tipo"] ?? ""
);

$placaGuincho = strtoupper(
    preg_replace(
        '/[^A-Za-z0-9]/',
        '',
        $dados["placa_guincho"] ?? ""
    )
);

$tipoGuincho = trim(
    $dados["tipo_guincho"] ?? ""
);

/*
|--------------------------------------------------------------------------
| VALIDAÇÕES
|--------------------------------------------------------------------------
*/

if ($nome === "") {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe seu nome."
    ]);

    exit;
}

if (!filter_var(
    $email,
    FILTER_VALIDATE_EMAIL
)) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe um e-mail válido."
    ]);

    exit;
}

if (strlen($telefone) !== 11) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe um celular válido."
    ]);

    exit;
}

if (strlen($senha) < 6) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "A senha deve possuir pelo menos 6 caracteres."
    ]);

    exit;
}

if (
    $tipo !== "cliente" &&
    $tipo !== "motorista"
) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Tipo de conta inválido."
    ]);

    exit;
}

if (
    $tipo === "motorista" &&
    strlen($placaGuincho) !== 7
) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe uma placa de guincho válida."
    ]);

    exit;
}

if (
    $tipo === "motorista" &&
    $tipoGuincho !== "Leve" &&
    $tipoGuincho !== "Pesado"
) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Selecione um tipo de guincho válido."
    ]);

    exit;
}

if ($tipo === "cliente") {
    $placaGuincho = null;
    $tipoGuincho = null;
}

/*
|--------------------------------------------------------------------------
| VERIFICA SE O E-MAIL JÁ EXISTE
|--------------------------------------------------------------------------
*/

$stmt = $conn->prepare("
    SELECT
        id,
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

$resultado =
    $stmt->get_result();

if ($resultado->num_rows > 0) {
    $existente =
        $resultado->fetch_assoc();

    if (
        intval(
            $existente["email_verificado"]
        ) === 1
    ) {
        http_response_code(409);

        echo json_encode([
            "sucesso" => false,
            "mensagem" => "Já existe uma conta com este e-mail."
        ]);

        exit;
    }

    http_response_code(409);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Este e-mail já possui um cadastro aguardando verificação."
    ]);

    exit;
}

/*
|--------------------------------------------------------------------------
| GERA SENHA E CÓDIGO
|--------------------------------------------------------------------------
*/

$senhaHash = password_hash(
    $senha,
    PASSWORD_DEFAULT
);

$codigo =
    gerarCodigo6Digitos();

$codigoHash =
    criarHashCodigo(
        $codigo
    );

$expira = date(
    "Y-m-d H:i:s",
    time() + 600
);

/*
|--------------------------------------------------------------------------
| CRIA CONTA
|--------------------------------------------------------------------------
*/

$conn->begin_transaction();

try {
    $stmt = $conn->prepare("
        INSERT INTO usuarios (
            nome,
            email,
            email_verificado,
            codigo_verificacao_hash,
            codigo_verificacao_expira,
            senha_hash,
            tipo,
            telefone,
            placa_guincho,
            tipo_guincho,
            disponivel
        )
        VALUES (
            ?,
            ?,
            0,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            0
        )
    ");

    $stmt->bind_param(
        "sssssssss",
        $nome,
        $email,
        $codigoHash,
        $expira,
        $senhaHash,
        $tipo,
        $telefone,
        $placaGuincho,
        $tipoGuincho
    );

    if (!$stmt->execute()) {
        throw new RuntimeException(
            $stmt->error
        );
    }

    $html = htmlCodigo(
        $nome,
        $codigo,
        "Use o código abaixo para confirmar seu e-mail e concluir seu cadastro."
    );

    enviarEmailHook(
        $email,
        $nome,
        "Confirme seu e-mail - Hook",
        $html,
        "Seu código de verificação do Hook é: {$codigo}. Ele expira em 10 minutos."
    );

    $conn->commit();

    echo json_encode([
        "sucesso" => true,
        "mensagem" => "Cadastro iniciado. Enviamos um código para seu e-mail.",
        "email" => $email,
        "tipo" => $tipo,
        "tipo_guincho" => $tipoGuincho,
        "requer_verificacao" => true
    ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    $conn->rollback();

    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Não foi possível criar a conta ou enviar o e-mail.",
        "erro" => $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}