<?php

header("Content-Type: application/json; charset=UTF-8");

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

$solicitacaoId = intval(
    $dados["solicitacao_id"] ?? 0
);

$motoristaId = intval(
    $dados["motorista_id"] ?? 0
);

if ($solicitacaoId <= 0 || $motoristaId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "solicitacao_id e motorista_id são obrigatórios."
    ]);

    exit;
}

/*
|--------------------------------------------------------------------------
| VERIFICA SE O MOTORISTA EXISTE
|--------------------------------------------------------------------------
*/

$stmt = $conn->prepare("
    SELECT id
    FROM usuarios
    WHERE id = ?
      AND tipo = 'motorista'
    LIMIT 1
");

$stmt->bind_param("i", $motoristaId);
$stmt->execute();

$resultado = $stmt->get_result();

if ($resultado->num_rows === 0) {
    http_response_code(404);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Motorista não encontrado."
    ]);

    exit;
}

/*
|--------------------------------------------------------------------------
| TENTA ACEITAR A SOLICITAÇÃO
|--------------------------------------------------------------------------
|
| Só aceita se ainda estiver buscando e sem motorista.
| Isso impede dois motoristas de aceitarem a mesma corrida.
|
*/

$stmt = $conn->prepare("
    UPDATE solicitacoes

    SET
        motorista_id = ?,
        status = 'aceito',
        updated_at = CURRENT_TIMESTAMP

    WHERE id = ?
      AND status = 'buscando'
      AND motorista_id IS NULL
");

$stmt->bind_param(
    "ii",
    $motoristaId,
    $solicitacaoId
);

$stmt->execute();

if ($stmt->affected_rows === 0) {
    http_response_code(409);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Essa solicitação já foi aceita ou não está mais disponível."
    ]);

    exit;
}

/*
|--------------------------------------------------------------------------
| MOTORISTA FICA INDISPONÍVEL
|--------------------------------------------------------------------------
*/

$stmt = $conn->prepare("
    UPDATE usuarios
    SET disponivel = 0
    WHERE id = ?
      AND tipo = 'motorista'
");

$stmt->bind_param(
    "i",
    $motoristaId
);

$stmt->execute();

/*
|--------------------------------------------------------------------------
| RESPOSTA
|--------------------------------------------------------------------------
*/

echo json_encode([
    "sucesso" => true,
    "mensagem" => "Solicitação aceita.",
    "solicitacao_id" => $solicitacaoId,
    "motorista_id" => $motoristaId,
    "status" => "aceito"
]);