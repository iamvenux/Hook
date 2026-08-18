<?php
/**
 * Cole este bloco dentro do seu app/Config/Routes.php existente
 * (dentro do escopo padrão, junto das outras rotas).
 *
 * Rotas públicas: registro e login.
 * Rotas protegidas: tudo dentro do grupo 'api', que passa pelo
 * TokenAuthFilter (Authorization: Bearer <token>).
 */

// ── Autenticação (públicas) ──────────────────────────────
$routes->post('api/auth/registro', 'Api\AuthController::registro');
$routes->post('api/auth/login',    'Api\AuthController::login');

// ── Rotas protegidas por token ───────────────────────────
$routes->group('api', ['filter' => 'tokenAuth'], function ($routes) {

    $routes->post('auth/logout', 'Api\AuthController::logout');

    // Veículos
    $routes->get('veiculos',        'Api\VeiculoController::index');
    $routes->post('veiculos',       'Api\VeiculoController::create');
    $routes->put('veiculos/(:num)', 'Api\VeiculoController::update/$1');
    $routes->delete('veiculos/(:num)', 'Api\VeiculoController::delete/$1');

    // Solicitações (cliente)
    $routes->post('solicitacoes',            'Api\SolicitacaoController::create');
    $routes->get('solicitacoes/(:num)',      'Api\SolicitacaoController::show/$1');
    $routes->get('solicitacoes/minhas',      'Api\SolicitacaoController::minhasSolicitacoes');
    $routes->post('solicitacoes/(:num)/cancelar', 'Api\SolicitacaoController::cancelar/$1');

    // Solicitações (motorista)
    $routes->get('solicitacoes/disponiveis',      'Api\SolicitacaoController::disponiveis');
    $routes->post('solicitacoes/(:num)/aceitar',  'Api\SolicitacaoController::aceitar/$1');
    $routes->post('solicitacoes/(:num)/status',   'Api\SolicitacaoController::atualizarStatus/$1');

    // Avaliação
    $routes->post('avaliacoes', 'Api\AvaliacaoController::create');
});
