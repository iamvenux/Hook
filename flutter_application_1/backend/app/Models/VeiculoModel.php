<?php

namespace App\Models;

use CodeIgniter\Model;

class VeiculoModel extends Model
{
    protected $table         = 'veiculos';
    protected $primaryKey    = 'id';
    protected $returnType    = 'array';
    protected $useTimestamps = false; // só tem created_at, sem updated_at

    protected $allowedFields = [
        'usuario_id',
        'tipo',
        'marca',
        'modelo',
        'ano',
        'placa',
        'cor',
        'created_at',
    ];

    protected $validationRules = [
        'usuario_id' => 'required|integer',
        'tipo'       => 'required|in_list[Carro,Moto,SUV]',
        'marca'      => 'required|max_length[60]',
        'modelo'     => 'required|max_length[60]',
        'placa'      => 'required|max_length[10]',
    ];

    public function listarPorUsuario(int $usuarioId): array
    {
        return $this->where('usuario_id', $usuarioId)->findAll();
    }
}
