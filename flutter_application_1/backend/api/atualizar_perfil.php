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

$nome = trim(
    $dados["nome"] ?? ""
);

$telefone = preg_replace(
    '/\D/',
    '',
    $dados["telefone"] ?? ""
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

if ($usuarioId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Usuário inválido."
    ]);

    exit;
}

if ($nome === "") {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe seu nome."
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

// Descobre o tipo do usuário para saber quais campos aceitar.
$stmt = $conn->prepare("
    SELECT tipo
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

$tipo = $resultado->fetch_assoc()["tipo"];

if ($tipo === "motorista") {
    if (strlen($placaGuincho) !== 7) {
        http_response_code(400);

        echo json_encode([
            "sucesso" => false,
            "mensagem" => "Informe uma placa de guincho válida."
        ]);

        exit;
    }

    if (
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
}

/*
|--------------------------------------------------------------------------
| ATUALIZA
|--------------------------------------------------------------------------
*/

if ($tipo === "motorista") {
    $stmt = $conn->prepare("
        UPDATE usuarios
        SET
            nome = ?,
            telefone = ?,
            placa_guincho = ?,
            tipo_guincho = ?
        WHERE id = ?
    ");

    $stmt->bind_param(
        "ssssi",
        $nome,
        $telefone,
        $placaGuincho,
        $tipoGuincho,
        $usuarioId
    );
} else {
    // Cliente não tem guincho: não mexe nesses campos.
    $stmt = $conn->prepare("
        UPDATE usuarios
        SET
            nome = ?,
            telefone = ?
        WHERE id = ?
    ");

    $stmt->bind_param(
        "ssi",
        $nome,
        $telefone,
        $usuarioId
    );
}

if (!$stmt->execute()) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Erro ao atualizar os dados."
    ]);

    exit;
}

// Devolve os dados já salvos, para o app atualizar a tela.
$stmt = $conn->prepare("
    SELECT
        id,
        nome,
        email,
        tipo,
        telefone,
        placa_guincho,
        tipo_guincho
    FROM usuarios
    WHERE id = ?
    LIMIT 1
");

$stmt->bind_param(
    "i",
    $usuarioId
);

$stmt->execute();

$usuario = $stmt->get_result()->fetch_assoc();

echo json_encode([
    "sucesso" => true,
    "mensagem" => "Dados atualizados com sucesso.",
    "usuario" => [
        "id" => intval($usuario["id"]),
        "nome" => $usuario["nome"],
        "email" => $usuario["email"],
        "tipo" => $usuario["tipo"],
        "telefone" => $usuario["telefone"],
        "placa_guincho" => $usuario["placa_guincho"],
        "tipo_guincho" => $usuario["tipo_guincho"]
    ]
], JSON_UNESCAPED_UNICODE);
