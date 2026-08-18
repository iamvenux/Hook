<?php

namespace App\Models;

use CodeIgniter\Model;

class AvaliacaoModel extends Model
{
    protected $table         = 'avaliacoes';
    protected $primaryKey    = 'id';
    protected $returnType    = 'array';
    protected $useTimestamps = false;

    protected $allowedFields = [
        'solicitacao_id',
        'nota',
        'created_at',
    ];

    protected $validationRules = [
        'solicitacao_id' => 'required|integer|is_unique[avaliacoes.solicitacao_id]',
        'nota'           => 'required|integer|greater_than[0]|less_than[6]',
    ];
}
