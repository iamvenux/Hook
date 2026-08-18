<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateSolicitacoes extends Migration
{
    public function up()
    {
        $this->forge->addField([
            'id' => [
                'type'           => 'INT',
                'constraint'     => 5,
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'cliente_id' => [
                'type'       => 'INT',
                'constraint' => 5,
                'unsigned'   => true,
            ],
            'motorista_id' => [
                'type'       => 'INT',
                'constraint' => 5,
                'unsigned'   => true,
                'null'       => true,
            ],
            'veiculo_id' => [
                'type'       => 'INT',
                'constraint' => 5,
                'unsigned'   => true,
            ],
            'tipo_reboque' => [
                'type'       => 'ENUM',
                'constraint' => ['Guincho Leve', 'Guincho Pesado'],
            ],
            'forma_pagamento' => [
                'type'       => 'ENUM',
                'constraint' => ['Pix', 'Dinheiro'],
            ],
            'endereco' => [
                'type'       => 'VARCHAR',
                'constraint' => 255,
            ],
            'latitude' => [
                'type'       => 'DECIMAL',
                'constraint' => '10,7',
            ],
            'longitude' => [
                'type'       => 'DECIMAL',
                'constraint' => '10,7',
            ],
            'valor_estimado' => [
                'type'       => 'DECIMAL',
                'constraint' => '10,2',
            ],
            'status' => [
                'type'       => 'ENUM',
                'constraint' => ['buscando', 'aceito', 'a_caminho', 'concluido', 'cancelado'],
                'default'    => 'buscando',
            ],
            'created_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
            'updated_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
        ]);

        $this->forge->addKey('id', true);
        $this->forge->addKey('status');
        $this->forge->addKey('cliente_id');
        $this->forge->addKey('motorista_id');
        $this->forge->addForeignKey('cliente_id', 'usuarios', 'id');
        $this->forge->addForeignKey('motorista_id', 'usuarios', 'id');
        $this->forge->addForeignKey('veiculo_id', 'veiculos', 'id');
        $this->forge->createTable('solicitacoes');
    }

    public function down()
    {
        $this->forge->dropTable('solicitacoes');
    }
}
