<?php

header('Content-Type: application/json; charset=utf-8');

require_once __DIR__ . "/../cors.php";
require_once __DIR__ . '/../config/banco.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST' &&
    $_SERVER['REQUEST_METHOD'] !== 'PUT') {

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

$clienteId = isset($dados['cliente_id'])
    ? (int)$dados['cliente_id']
    : 0;


if ($solicitacaoId <= 0) {

    http_response_code(400);

    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'solicitacao_id é obrigatório.'
    ]);

    exit;
}


/*
|--------------------------------------------------------------------------
| Cliente pode cancelar a própria solicitação
|--------------------------------------------------------------------------
*/

if ($clienteId > 0) {

    $stmt = $pdo->prepare(
        "UPDATE solicitacoes

         SET status = 'cancelado',
             updated_at = NOW()

         WHERE id = ?
           AND cliente_id = ?
           AND status IN (
               'buscando',
               'aceito',
               'a_caminho',
               'no_local'
           )"
    );

    $stmt->execute([
        $solicitacaoId,
        $clienteId
    ]);

} else {

    /*
    |--------------------------------------------------------------------------
    | Caso seja usado sem cliente_id
    |--------------------------------------------------------------------------
    */

    $stmt = $pdo->prepare(
        "UPDATE solicitacoes

         SET status = 'cancelado',
             updated_at = NOW()

         WHERE id = ?

           AND status IN (
               'buscando',
               'aceito',
               'a_caminho',
               'no_local'
           )"
    );

    $stmt->execute([
        $solicitacaoId
    ]);
}


if ($stmt->rowCount() === 0) {

    http_response_code(409);

    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Não foi possível cancelar. A solicitação pode já ter sido concluída, cancelada ou não pertence ao cliente.'
    ]);

    exit;
}


echo json_encode([
    'sucesso' => true,
    'mensagem' => 'Solicitação cancelada com sucesso.',
    'solicitacao_id' => $solicitacaoId,
    'status' => 'cancelado'
]);