<?php

namespace App\Controllers\Api;

use App\Models\SolicitacaoModel;
use App\Models\UsuarioModel;
use App\Models\VeiculoModel;

class SolicitacaoController extends BaseApiController
{
    // POST /api/solicitacoes — cliente cria um pedido de reboque
    public function create()
    {
        $usuario = $this->usuarioAutenticado();
        if (!$usuario || $usuario['tipo'] !== 'cliente') {
            return $this->failForbidden('Só clientes podem solicitar reboque.');
        }

        $dados = $this->request->getJSON(true);

        $regras = [
            'veiculo_id'      => 'required|integer',
            'tipo_reboque'    => 'required|in_list[Guincho Leve,Guincho Pesado]',
            'forma_pagamento' => 'required|in_list[Pix,Dinheiro]',
            'endereco'        => 'required',
            'latitude'        => 'required|decimal',
            'longitude'       => 'required|decimal',
        ];

        if (!$this->validateData($dados, $regras)) {
            return $this->failValidationErrors($this->validator->getErrors());
        }

        // Confere se o veículo é mesmo do cliente logado.
        $veiculo = (new VeiculoModel())->find($dados['veiculo_id']);
        if (!$veiculo || (int) $veiculo['usuario_id'] !== (int) $usuario['id']) {
            return $this->failNotFound('Veículo não encontrado.');
        }

        $model = new SolicitacaoModel();

        $solicitacaoId = $model->insert([
            'cliente_id'      => $usuario['id'],
            'veiculo_id'      => $dados['veiculo_id'],
            'tipo_reboque'    => $dados['tipo_reboque'],
            'forma_pagamento' => $dados['forma_pagamento'],
            'endereco'        => $dados['endereco'],
            'latitude'        => $dados['latitude'],
            'longitude'       => $dados['longitude'],
            // Preço fixo por tipo — ver SolicitacaoModel::PRECOS.
            'valor_estimado'  => SolicitacaoModel::PRECOS[$dados['tipo_reboque']],
            'status'          => 'buscando',
        ]);

        if (!$solicitacaoId) {
            return $this->failServerError('Não foi possível criar a solicitação.');
        }

        return $this->respondCreated(['solicitacao' => $model->find($solicitacaoId)]);
    }

    // GET /api/solicitacoes/{id} — usado pelo app do cliente pra fazer
    // polling do status (equivalente ao ProcurandoProfissionalScreen).
    public function show($id = null)
    {
        $usuario = $this->usuarioAutenticado();
        if (!$usuario) {
            return $this->failUnauthorized('Não autenticado.');
        }

        $model       = new SolicitacaoModel();
        $solicitacao = $model->find($id);

        if (!$solicitacao) {
            return $this->failNotFound('Solicitação não encontrada.');
        }

        $ehDono = (int) $solicitacao['cliente_id'] === (int) $usuario['id'];
        $ehMotoristaAtribuido = $solicitacao['motorista_id']
            && (int) $solicitacao['motorista_id'] === (int) $usuario['id'];

        if (!$ehDono && !$ehMotoristaAtribuido) {
            return $this->failForbidden('Sem acesso a essa solicitação.');
        }

        $resposta = ['solicitacao' => $solicitacao];

        // Mensagens amigáveis pro app mostrar direto no painel de rastreio,
        // sem precisar traduzir o status na tela.
        $resposta['mensagem'] = match ($solicitacao['status']) {
            'buscando'  => 'Procurando o guincho mais próximo...',
            'aceito'    => 'Guincho encontrado! A caminho.',
            'a_caminho' => 'Seu guincho está a caminho.',
            'concluido' => 'Serviço concluído.',
            'cancelado' => 'Solicitação cancelada.',
            default     => null,
        };

        // Se já tem motorista, manda os dados básicos dele junto
        // (nome, telefone, placa do guincho, localização atual).
        if ($solicitacao['motorista_id']) {
            $motorista = (new UsuarioModel())->find($solicitacao['motorista_id']);
            if ($motorista) {
                $resposta['motorista'] = [
                    'nome'      => $motorista['nome'],
                    'telefone'  => $motorista['telefone'],
                    'placa'     => $motorista['placa_guincho'],
                    'latitude'  => $motorista['latitude_atual'],
                    'longitude' => $motorista['longitude_atual'],
                ];
            }
        }

        return $this->respond($resposta);
    }

    // GET /api/solicitacoes/minhas — histórico do cliente logado
    public function minhasSolicitacoes()
    {
        $usuario = $this->usuarioAutenticado();
        if (!$usuario || $usuario['tipo'] !== 'cliente') {
            return $this->failForbidden('Só clientes têm histórico de solicitações.');
        }

        $solicitacoes = (new SolicitacaoModel())->listarPorCliente($usuario['id']);

        return $this->respond(['solicitacoes' => $solicitacoes]);
    }

    // POST /api/solicitacoes/{id}/cancelar
    public function cancelar($id = null)
    {
        $usuario = $this->usuarioAutenticado();
        if (!$usuario) {
            return $this->failUnauthorized('Não autenticado.');
        }

        $model       = new SolicitacaoModel();
        $solicitacao = $model->find($id);

        if (!$solicitacao || (int) $solicitacao['cliente_id'] !== (int) $usuario['id']) {
            return $this->failNotFound('Solicitação não encontrada.');
        }

        if (in_array($solicitacao['status'], ['concluido', 'cancelado'], true)) {
            return $this->fail('Essa solicitação não pode mais ser cancelada.', 409);
        }

        $model->update($id, ['status' => 'cancelado']);

        return $this->respond(['mensagem' => 'Solicitação cancelada.']);
    }

    // ── Lado do motorista ────────────────────────────────

    // GET /api/solicitacoes/disponiveis — fila de pedidos esperando motorista
    public function disponiveis()
    {
        $usuario = $this->usuarioAutenticado();
        if (!$usuario || $usuario['tipo'] !== 'motorista') {
            return $this->failForbidden('Só motoristas podem ver a fila de solicitações.');
        }

        $solicitacoes = (new SolicitacaoModel())->listarDisponiveisParaMotorista();

        return $this->respond(['solicitacoes' => $solicitacoes]);
    }

    // POST /api/solicitacoes/{id}/aceitar
    //
    // Importante: o UPDATE só acontece se status ainda for 'buscando'.
    // Isso evita dois motoristas aceitando a mesma corrida ao mesmo
    // tempo (mesma proteção que o RideService.acceptRide do Felipe
    // fazia no Node, só que aqui via WHERE condicional no MySQL).
    public function aceitar($id = null)
    {
        $usuario = $this->usuarioAutenticado();
        if (!$usuario || $usuario['tipo'] !== 'motorista') {
            return $this->failForbidden('Só motoristas podem aceitar solicitações.');
        }

        $db = \Config\Database::connect();

        $linhasAfetadas = $db->table('solicitacoes')
            ->where('id', $id)
            ->where('status', 'buscando')
            ->update([
                'motorista_id' => $usuario['id'],
                'status'       => 'aceito',
                'updated_at'   => date('Y-m-d H:i:s'),
            ]);

        if ($db->affectedRows() === 0) {
            return $this->fail('Essa solicitação já foi aceita por outro motorista.', 409);
        }

        $solicitacao = (new SolicitacaoModel())->find($id);

        return $this->respond([
            'mensagem'    => 'Solicitação aceita!',
            'solicitacao' => $solicitacao,
        ]);
    }

    // POST /api/solicitacoes/{id}/status
    // body: { "status": "a_caminho" | "concluido" | "cancelado" }
    public function atualizarStatus($id = null)
    {
        $usuario = $this->usuarioAutenticado();
        if (!$usuario || $usuario['tipo'] !== 'motorista') {
            return $this->failForbidden('Só motoristas podem atualizar o status.');
        }

        $model       = new SolicitacaoModel();
        $solicitacao = $model->find($id);

        if (!$solicitacao || (int) $solicitacao['motorista_id'] !== (int) $usuario['id']) {
            return $this->failNotFound('Solicitação não encontrada.');
        }

        $dados          = $this->request->getJSON(true);
        $statusValidos  = ['a_caminho', 'concluido', 'cancelado'];

        if (!in_array($dados['status'] ?? null, $statusValidos, true)) {
            return $this->failValidationErrors('Status inválido. Use: ' . implode(', ', $statusValidos));
        }

        $model->update($id, ['status' => $dados['status']]);

        return $this->respond(['solicitacao' => $model->find($id)]);
    }
}
