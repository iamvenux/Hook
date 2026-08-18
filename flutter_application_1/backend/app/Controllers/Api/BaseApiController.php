<?php

namespace App\Controllers\Api;

use App\Models\UsuarioModel;
use CodeIgniter\RESTful\ResourceController;

/**
 * Base pros controllers da API que exigem login.
 * O TokenAuthFilter já bloqueia quem não manda token válido;
 * aqui a gente só recupera os dados do usuário logado pra usar
 * dentro do controller (ex.: pegar o cliente_id da solicitação).
 */
abstract class BaseApiController extends ResourceController
{
    protected $format = 'json';

    protected function usuarioAutenticado(): ?array
    {
        $header = $this->request->getHeaderLine('Authorization');
        if (!$header || !str_starts_with($header, 'Bearer ')) {
            return null;
        }

        $token = trim(substr($header, 7));

        return (new UsuarioModel())->buscarPorToken($token);
    }
}
