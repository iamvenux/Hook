<?php

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . '/../config/banco.php';

if ($_SERVER['REQUEST_METHOD'] !== 'PUT' &&
    $_SERVER['REQUEST_METHOD'] !== 'POST') {

    http_response_code(405);

    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Método não permitido.'
    ]);

    exit;
}

$dados = json_decode(file_get_contents('php://input'), true);

if (!is_array($dados)) {
    $dados = $_POST;
}

$solicitacaoId = isset($dados['solicitacao_id'])
    ? (int)$dados['solicitacao_id']
    : 0;

$motoristaId = isset($dados['motorista_id'])
    ? (int)$dados['motorista_id']
    : 0;

$status = trim($dados['status'] ?? '');


$statusesPermitidos = [
    'aceito',
    'a_caminho',
    'no_local',
    'em_atendimento',
    'concluido'
];

if ($solicitacaoId <= 0 ||
    $motoristaId <= 0 ||
    $status === '') {

    http_response_code(400);

    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'solicitacao_id, motorista_id e status são obrigatórios.'
    ]);

    exit;
}

if (!in_array($status, $statusesPermitidos, true)) {

    http_response_code(400);

    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Status inválido.'
    ]);

    exit;
}


/*
|--------------------------------------------------------------------------
| Verifica se a solicitação pertence ao motorista
|--------------------------------------------------------------------------
*/

$stmt = $pdo->prepare(
    "SELECT id, status
     FROM solicitacoes
     WHERE id = ?
       AND motorista_id = ?
     LIMIT 1"
);

$stmt->execute([
    $solicitacaoId,
    $motoristaId
]);

$solicitacao = $stmt->fetch();

if (!$solicitacao) {

    http_response_code(403);

    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Esta solicitação não pertence a este motorista.'
    ]);

    exit;
}


/*
|--------------------------------------------------------------------------
| Validação da sequência dos status
|--------------------------------------------------------------------------
*/

$ordem = [
    'aceito' => 1,
    'a_caminho' => 2,
    'no_local' => 3,
    'em_atendimento' => 4,
    'concluido' => 5
];

$statusAtual = $solicitacao['status'];

if ($statusAtual !== 'cancelado' &&
    isset($ordem[$statusAtual]) &&
    isset($ordem[$status]) &&
    $ordem[$status] < $ordem[$statusAtual]) {

    http_response_code(409);

    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Não é possível voltar para um status anterior.'
    ]);

    exit;
}


/*
|--------------------------------------------------------------------------
| Atualiza
|--------------------------------------------------------------------------
*/

$stmt = $pdo->prepare(
    "UPDATE solicitacoes
     SET status = ?,
         updated_at = NOW()
     WHERE id = ?
       AND motorista_id = ?"
);

$stmt->execute([
    $status,
    $solicitacaoId,
    $motoristaId
]);


echo json_encode([
    'sucesso' => true,
    'mensagem' => 'Status atualizado com sucesso.',
    'solicitacao_id' => $solicitacaoId,
    'status' => $status
]);