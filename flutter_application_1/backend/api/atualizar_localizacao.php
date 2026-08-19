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

$motoristaId = isset($dados['motorista_id'])
    ? (int)$dados['motorista_id']
    : 0;

$latitude = isset($dados['latitude'])
    ? (float)$dados['latitude']
    : null;

$longitude = isset($dados['longitude'])
    ? (float)$dados['longitude']
    : null;


if ($motoristaId <= 0) {

    http_response_code(400);

    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'motorista_id é obrigatório.'
    ]);

    exit;
}

if ($latitude === null || $longitude === null) {

    http_response_code(400);

    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Latitude e longitude são obrigatórias.'
    ]);

    exit;
}


/*
|--------------------------------------------------------------------------
| Validação simples das coordenadas
|--------------------------------------------------------------------------
*/

if ($latitude < -90 || $latitude > 90) {

    http_response_code(400);

    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Latitude inválida.'
    ]);

    exit;
}

if ($longitude < -180 || $longitude > 180) {

    http_response_code(400);

    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Longitude inválida.'
    ]);

    exit;
}


/*
|--------------------------------------------------------------------------
| Atualiza localização
|--------------------------------------------------------------------------
*/

$stmt = $pdo->prepare(
    "UPDATE usuarios
     SET latitude_atual = ?,
         longitude_atual = ?,
         updated_at = NOW()
     WHERE id = ?
       AND tipo = 'motorista'"
);

$stmt->execute([
    $latitude,
    $longitude,
    $motoristaId
]);

if ($stmt->rowCount() === 0) {

    /*
    | Pode ser que a localização enviada seja igual à anterior.
    | Por isso verificamos se o motorista existe.
    */

    $stmt = $pdo->prepare(
        "SELECT id
         FROM usuarios
         WHERE id = ?
           AND tipo = 'motorista'
         LIMIT 1"
    );

    $stmt->execute([$motoristaId]);

    if (!$stmt->fetch()) {

        http_response_code(404);

        echo json_encode([
            'sucesso' => false,
            'mensagem' => 'Motorista não encontrado.'
        ]);

        exit;
    }
}


echo json_encode([
    'sucesso' => true,
    'mensagem' => 'Localização atualizada.',
    'motorista_id' => $motoristaId,
    'latitude' => $latitude,
    'longitude' => $longitude
]);