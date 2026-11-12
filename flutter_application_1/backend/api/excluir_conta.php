<?php

header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . "/../cors.php";
require_once __DIR__ . "/../conexao.php";

/*
|--------------------------------------------------------------------------
| EXCLUSÃO DE CONTA
|--------------------------------------------------------------------------
|
| As solicitações referenciam o usuário (cliente e motorista) sem
| ON DELETE CASCADE, e o histórico da outra parte precisa continuar
| existindo. Por isso a conta não é apagada fisicamente: os dados
| pessoais são anonimizados, o login deixa de funcionar e os
| veículos/endereços são removidos.
|
*/

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

$senha = $dados["senha"] ?? "";

if ($usuarioId <= 0 || $senha === "") {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe sua senha para excluir a conta."
    ]);

    exit;
}

$stmt = $conn->prepare("
    SELECT
        id,
        senha_hash,
        tipo
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
    $senha,
    $usuario["senha_hash"]
)) {
    http_response_code(401);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Senha incorreta."
    ]);

    exit;
}

$conn->begin_transaction();

try {
    // E-mail único e inválido, para liberar o original para novo cadastro.
    $emailAnonimo =
        "excluido_" . $usuarioId . "_" . time() . "@hook.invalid";

    // Senha aleatória: ninguém consegue mais entrar nesta conta.
    $senhaAnonima = password_hash(
        bin2hex(random_bytes(16)),
        PASSWORD_DEFAULT
    );

    $stmt = $conn->prepare("
        UPDATE usuarios
        SET
            nome = 'Conta excluída',
            email = ?,
            email_verificado = 0,
            codigo_verificacao_hash = NULL,
            codigo_verificacao_expira = NULL,
            codigo_recuperacao_hash = NULL,
            codigo_recuperacao_expira = NULL,
            senha_hash = ?,
            telefone = NULL,
            placa_guincho = NULL,
            tipo_guincho = NULL,
            disponivel = 0,
            latitude_atual = NULL,
            longitude_atual = NULL,
            api_token = NULL
        WHERE id = ?
    ");

    $stmt->bind_param(
        "ssi",
        $emailAnonimo,
        $senhaAnonima,
        $usuarioId
    );

    if (!$stmt->execute()) {
        throw new RuntimeException($stmt->error);
    }

    // Solicitações do cliente ainda em aberto são canceladas.
    if ($usuario["tipo"] === "cliente") {
        $stmt = $conn->prepare("
            UPDATE solicitacoes
            SET status = 'cancelado'
            WHERE cliente_id = ?
              AND status NOT IN ('concluido', 'cancelado')
        ");

        $stmt->bind_param(
            "i",
            $usuarioId
        );

        if (!$stmt->execute()) {
            throw new RuntimeException($stmt->error);
        }
    }

    // Veículos somem da lista (exclusão lógica, como em excluir_veiculo.php).
    $stmt = $conn->prepare("
        UPDATE veiculos
        SET
            ativo = 0,
            padrao = 0
        WHERE usuario_id = ?
    ");

    $stmt->bind_param(
        "i",
        $usuarioId
    );

    if (!$stmt->execute()) {
        throw new RuntimeException($stmt->error);
    }

    $stmt = $conn->prepare("
        DELETE FROM enderecos
        WHERE usuario_id = ?
    ");

    $stmt->bind_param(
        "i",
        $usuarioId
    );

    if (!$stmt->execute()) {
        throw new RuntimeException($stmt->error);
    }

    $conn->commit();

    echo json_encode([
        "sucesso" => true,
        "mensagem" => "Conta excluída com sucesso."
    ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    $conn->rollback();

    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Não foi possível excluir a conta."
    ], JSON_UNESCAPED_UNICODE);
}
