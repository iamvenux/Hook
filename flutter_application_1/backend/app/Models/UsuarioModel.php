<?php

namespace App\Models;

use CodeIgniter\Model;

class UsuarioModel extends Model
{
    protected $table            = 'usuarios';
    protected $primaryKey       = 'id';
    protected $returnType       = 'array';
    protected $useTimestamps    = true;
    protected $createdField     = 'created_at';
    protected $updatedField     = 'updated_at';

    protected $allowedFields = [
        'nome',
        'email',
        'senha_hash',
        'tipo',
        'telefone',
        'placa_guincho',
        'disponivel',
        'latitude_atual',
        'longitude_atual',
        'api_token',
    ];

    protected $validationRules = [
        'nome'  => 'required|min_length[2]|max_length[120]',
        'email' => 'required|valid_email|is_unique[usuarios.email,id,{id}]',
        'tipo'  => 'required|in_list[cliente,motorista]',
    ];

    // Nunca devolve a senha (hash) nem o token nas respostas da API.
    public function paraApi(array $usuario): array
    {
        unset($usuario['senha_hash'], $usuario['api_token']);
        return $usuario;
    }

    public function buscarPorToken(string $token): ?array
    {
        return $this->where('api_token', $token)->first();
    }

    public function buscarPorEmail(string $email): ?array
    {
        return $this->where('email', $email)->first();
    }

    // Motoristas disponíveis, ordenados pelo mais próximo do ponto
    // informado (fórmula de Haversine, distância em km).
    public function motoristasProximos(float $lat, float $lng, int $limite = 5): array
    {
        $sql = "
            SELECT *,
              (6371 * acos(
                cos(radians(?)) * cos(radians(latitude_atual)) *
                cos(radians(longitude_atual) - radians(?)) +
                sin(radians(?)) * sin(radians(latitude_atual))
              )) AS distancia_km
            FROM usuarios
            WHERE tipo = 'motorista'
              AND disponivel = 1
              AND latitude_atual IS NOT NULL
            ORDER BY distancia_km ASC
            LIMIT ?
        ";

        return $this->db->query($sql, [$lat, $lng, $lat, $limite])->getResultArray();
    }
}
