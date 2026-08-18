<?php

namespace App\Controllers\Api;

use App\Models\AvaliacaoModel;
use App\Models\SolicitacaoModel;

class AvaliacaoController extends BaseApiController
{
    // POST /api/avaliacoes
    // body: { "solicitacao_id": 12, "nota": 5 }
    public function create()
    {
        $usuario = $this->usuarioAutenticado();
        if (!$usuario) {
            return $this->failUnauthorized('Não autenticado.');
        }

        $dados = $this->request->getJSON(true);

        $solicitacao = (new SolicitacaoModel())->find($dados['solicitacao_id'] ?? null);

        if (!$solicitacao || (int) $solicitacao['cliente_id'] !== (int) $usuario['id']) {
            return $this->failNotFound('Solicitação não encontrada.');
        }

        if ($solicitacao['status'] !== 'concluido') {
            return $this->fail('Só é possível avaliar solicitações concluídas.', 409);
        }

        $model = new AvaliacaoModel();

        if (!$model->validate($dados)) {
            return $this->failValidationErrors($model->errors());
        }

        $avaliacaoId = $model->insert([
            'solicitacao_id' => $dados['solicitacao_id'],
            'nota'           => $dados['nota'],
            'created_at'     => date('Y-m-d H:i:s'),
        ]);

        return $this->respondCreated(['avaliacao' => $model->find($avaliacaoId)]);
    }
}
