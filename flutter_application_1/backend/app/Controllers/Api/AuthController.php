<?php

namespace App\Controllers\Api;

use App\Models\UsuarioModel;
use CodeIgniter\RESTful\ResourceController;

class AuthController extends ResourceController
{
    protected $format = 'json';

    // POST /api/auth/registro
    public function registro()
    {
        $model = new UsuarioModel();
        $dados = $this->request->getJSON(true);

        $regras = [
            'nome'  => 'required|min_length[2]|max_length[120]',
            'email' => 'required|valid_email|is_unique[usuarios.email]',
            'senha' => 'required|min_length[6]',
            'tipo'  => 'required|in_list[cliente,motorista]',
        ];

        if (!$this->validateData($dados, $regras)) {
            return $this->failValidationErrors($this->validator->getErrors());
        }

        $usuarioId = $model->insert([
            'nome'          => $dados['nome'],
            'email'         => $dados['email'],
            'senha_hash'    => password_hash($dados['senha'], PASSWORD_BCRYPT),
            'tipo'          => $dados['tipo'],
            'telefone'      => $dados['telefone']      ?? null,
            'placa_guincho' => $dados['placa_guincho'] ?? null,
        ]);

        if (!$usuarioId) {
            return $this->failServerError('Não foi possível criar o usuário.');
        }

        $usuario = $model->find($usuarioId);

        return $this->respondCreated([
            'usuario' => $model->paraApi($usuario),
        ]);
    }

    // POST /api/auth/login
    public function login()
    {
        $model = new UsuarioModel();
        $dados = $this->request->getJSON(true);

        $regras = [
            'email' => 'required|valid_email',
            'senha' => 'required',
        ];

        if (!$this->validateData($dados, $regras)) {
            return $this->failValidationErrors($this->validator->getErrors());
        }

        $usuario = $model->buscarPorEmail($dados['email']);

        if (!$usuario || !password_verify($dados['senha'], $usuario['senha_hash'])) {
            return $this->failUnauthorized('Email ou senha inválidos.');
        }

        // Gera um novo token a cada login. Simples e suficiente
        // pro escopo do TCC — sem expiração/refresh por enquanto.
        $token = bin2hex(random_bytes(32));
        $model->update($usuario['id'], ['api_token' => $token]);
        $usuario['api_token'] = $token;

        return $this->respond([
            'usuario' => $model->paraApi($usuario),
            'token'   => $token,
        ]);
    }

    // POST /api/auth/logout  (rota protegida — exige token)
    public function logout()
    {
        $header = $this->request->getHeaderLine('Authorization');
        $token  = trim(substr($header, 7));

        $model   = new UsuarioModel();
        $usuario = $model->buscarPorToken($token);

        if ($usuario) {
            $model->update($usuario['id'], ['api_token' => null]);
        }

        return $this->respondDeleted(['mensagem' => 'Sessão encerrada.']);
    }
}
