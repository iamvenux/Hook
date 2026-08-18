<?php

namespace App\Controllers\Api;

use App\Models\VeiculoModel;

class VeiculoController extends BaseApiController
{
    // GET /api/veiculos — lista os veículos do usuário logado
    public function index()
    {
        $usuario = $this->usuarioAutenticado();
        if (!$usuario) {
            return $this->failUnauthorized('Não autenticado.');
        }

        $veiculos = (new VeiculoModel())->listarPorUsuario($usuario['id']);

        return $this->respond(['veiculos' => $veiculos]);
    }

    // POST /api/veiculos — cadastra um veículo novo
    public function create()
    {
        $usuario = $this->usuarioAutenticado();
        if (!$usuario) {
            return $this->failUnauthorized('Não autenticado.');
        }

        $model = new VeiculoModel();
        $dados = $this->request->getJSON(true);
        $dados['usuario_id'] = $usuario['id'];
        $dados['created_at'] = date('Y-m-d H:i:s');

        if (!$model->validate($dados)) {
            return $this->failValidationErrors($model->errors());
        }

        $veiculoId = $model->insert($dados);

        return $this->respondCreated(['veiculo' => $model->find($veiculoId)]);
    }

    // PUT /api/veiculos/{id} — edita um veículo (só o dono pode editar)
    public function update($id = null)
    {
        $usuario = $this->usuarioAutenticado();
        if (!$usuario) {
            return $this->failUnauthorized('Não autenticado.');
        }

        $model    = new VeiculoModel();
        $veiculo  = $model->find($id);

        if (!$veiculo || (int) $veiculo['usuario_id'] !== (int) $usuario['id']) {
            return $this->failNotFound('Veículo não encontrado.');
        }

        $dados = $this->request->getJSON(true);
        unset($dados['usuario_id']); // não deixa trocar o dono

        $model->update($id, $dados);

        return $this->respond(['veiculo' => $model->find($id)]);
    }

    // DELETE /api/veiculos/{id}
    public function delete($id = null)
    {
        $usuario = $this->usuarioAutenticado();
        if (!$usuario) {
            return $this->failUnauthorized('Não autenticado.');
        }

        $model   = new VeiculoModel();
        $veiculo = $model->find($id);

        if (!$veiculo || (int) $veiculo['usuario_id'] !== (int) $usuario['id']) {
            return $this->failNotFound('Veículo não encontrado.');
        }

        $model->delete($id);

        return $this->respondDeleted(['mensagem' => 'Veículo removido.']);
    }
}
