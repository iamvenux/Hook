<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateVeiculos extends Migration
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
            'usuario_id' => [
                'type'       => 'INT',
                'constraint' => 5,
                'unsigned'   => true,
            ],
            'tipo' => [
                'type'       => 'ENUM',
                'constraint' => ['Carro', 'Moto', 'SUV'],
                'default'    => 'Carro',
            ],
            'marca' => [
                'type'       => 'VARCHAR',
                'constraint' => 60,
            ],
            'modelo' => [
                'type'       => 'VARCHAR',
                'constraint' => 60,
            ],
            'ano' => [
                'type'       => 'SMALLINT',
                'constraint' => 5,
                'unsigned'   => true,
                'null'       => true,
            ],
            'placa' => [
                'type'       => 'VARCHAR',
                'constraint' => 10,
            ],
            'cor' => [
                'type'       => 'VARCHAR',
                'constraint' => 30,
                'null'       => true,
            ],
            'created_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
        ]);

        $this->forge->addKey('id', true);
        $this->forge->addKey('usuario_id');
        $this->forge->addForeignKey('usuario_id', 'usuarios', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('veiculos');
    }

    public function down()
    {
        $this->forge->dropTable('veiculos');
    }
}
