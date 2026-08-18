<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateAvaliacoes extends Migration
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
            'solicitacao_id' => [
                'type'       => 'INT',
                'constraint' => 5,
                'unsigned'   => true,
            ],
            'nota' => [
                'type'       => 'TINYINT',
                'constraint' => 1,
                'unsigned'   => true,
            ],
            'created_at' => [
                'type' => 'DATETIME',
                'null' => true,
            ],
        ]);

        $this->forge->addKey('id', true);
        $this->forge->addUniqueKey('solicitacao_id');
        $this->forge->addForeignKey('solicitacao_id', 'solicitacoes', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('avaliacoes');
    }

    public function down()
    {
        $this->forge->dropTable('avaliacoes');
    }
}
