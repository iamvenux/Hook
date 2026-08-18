<?php

namespace App\Models;

use CodeIgniter\Model;

class SolicitacaoModel extends Model
{
    protected $table         = 'solicitacoes';
    protected $primaryKey    = 'id';
    protected $returnType    = 'array';
    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = 'updated_at';

    protected $allowedFields = [
        'cliente_id',
        'motorista_id',
        'veiculo_id',
        'tipo_reboque',
        'forma_pagamento',
        'endereco',
        'latitude',
        'longitude',
        'valor_estimado',
        'status',
    ];

    protected $validationRules = [
        'cliente_id'      => 'required|integer',
        'veiculo_id'      => 'required|integer',
        'tipo_reboque'    => 'required|in_list[Guincho Leve,Guincho Pesado]',
        'forma_pagamento' => 'required|in_list[Pix,Dinheiro]',
        'endereco'        => 'required',
        'latitude'        => 'required|decimal',
        'longitude'       => 'required|decimal',
    ];

    // Preço fixo por tipo de reboque — ajuste aqui se os valores mudarem.
    public const PRECOS = [
        'Guincho Leve'   => 350.00,
        'Guincho Pesado' => 550.00,
    ];

    public function listarDisponiveisParaMotorista(): array
    {
        return $this->where('status', 'buscando')
                    ->orderBy('created_at', 'ASC')
                    ->findAll();
    }

    public function listarPorCliente(int $clienteId): array
    {
        return $this->where('cliente_id', $clienteId)
                    ->orderBy('created_at', 'DESC')
                    ->findAll();
    }

    public function listarPorMotorista(int $motoristaId): array
    {
        return $this->where('motorista_id', $motoristaId)
                    ->orderBy('created_at', 'DESC')
                    ->findAll();
    }
}
