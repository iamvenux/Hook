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

$usuarioId = intval(
    $dados["usuario_id"] ?? 0
);

$senhaAtual = $dados["senha_atual"] ?? "";

$novaSenha = $dados["nova_senha"] ?? "";

/*
|--------------------------------------------------------------------------
| VALIDAÇÕES
|--------------------------------------------------------------------------
*/

if ($usuarioId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Usuário inválido."
    ]);

    exit;
}

if ($senhaAtual === "") {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe sua senha atual."
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
    SELECT senha_hash
    FROM usuarios
    WHERE id = ?
    LIMIT 1
");

$stmt->bind_param(
    "i",
    $usuarioId
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

if (!password_verify(
    $senhaAtual,
    $usuario["senha_hash"]
)) {
    http_response_code(401);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Senha atual incorreta."
    ]);

    exit;
}

/*
|--------------------------------------------------------------------------
| ATUALIZA
|--------------------------------------------------------------------------
*/

$novaSenhaHash = password_hash(
    $novaSenha,
    PASSWORD_DEFAULT
);

$stmt = $conn->prepare("
    UPDATE usuarios
    SET senha_hash = ?
    WHERE id = ?
");

$stmt->bind_param(
    "si",
    $novaSenhaHash,
    $usuarioId
);

if (!$stmt->execute()) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Erro ao alterar a senha."
    ]);

    exit;
}

echo json_encode([
    "sucesso" => true,
    "mensagem" => "Senha alterada com sucesso."
], JSON_UNESCAPED_UNICODE);
