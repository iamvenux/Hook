<?php

namespace App\Filters;

use App\Models\UsuarioModel;
use CodeIgniter\Filters\FilterInterface;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;

/**
 * Autenticação simples por token.
 *
 * O app Flutter envia o header:
 *   Authorization: Bearer <token>
 *
 * O token é gerado no login (Auth::login) e salvo em usuarios.api_token.
 * Sem JWT de propósito — pra um TCC, token opaco + tabela já resolve
 * e evita depender de uma lib externa via Composer.
 */
class TokenAuthFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null)
    {
        $header = $request->getHeaderLine('Authorization');

        if (!$header || !str_starts_with($header, 'Bearer ')) {
            return service('response')
                ->setStatusCode(401)
                ->setJSON(['erro' => 'Token não informado.']);
        }

        $token = trim(substr($header, 7));

        $usuarioModel = new UsuarioModel();
        $usuario      = $usuarioModel->buscarPorToken($token);

        if (!$usuario) {
            return service('response')
                ->setStatusCode(401)
                ->setJSON(['erro' => 'Token inválido ou expirado.']);
        }

        // O usuário autenticado é resolvido de novo dentro de cada
        // controller (via BaseApiController::usuarioAutenticado()) —
        // aqui o filtro só bloqueia quem não tem token válido.
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
        // Nada a fazer depois da resposta.
    }
}
