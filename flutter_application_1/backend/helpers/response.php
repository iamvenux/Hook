<?php

header('Content-Type: application/json; charset=utf-8');

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function responder($dados, int $status = 200): void
{
    http_response_code($status);

    echo json_encode(
        $dados,
        JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
    );

    exit;
}

function erro(string $mensagem, int $status = 400): void
{
    responder([
        'sucesso' => false,
        'mensagem' => $mensagem
    ], $status);
}

function sucesso(array $dados = [], int $status = 200): void
{
    responder(array_merge([
        'sucesso' => true
    ], $dados), $status);
}

function obterJson(): array
{
    $conteudo = file_get_contents('php://input');

    if (!$conteudo) {
        return [];
    }

    $dados = json_decode($conteudo, true);

    if (!is_array($dados)) {
        erro('JSON inválido.');
    }

    return $dados;
}