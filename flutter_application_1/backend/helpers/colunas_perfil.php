<?php

/**
 * Garante que as colunas usadas pelo perfil existam na tabela `usuarios`.
 * Roda de forma idempotente: só altera a tabela se faltar coluna,
 * então não é preciso executar SQL manualmente no phpMyAdmin.
 */
function garantirColunasPerfil(mysqli $conn): void
{
    static $verificado = false;

    if ($verificado) {
        return;
    }

    $colunas = [
        "foto_url"                 => "VARCHAR(255) NULL",
        "email_pendente"           => "VARCHAR(150) NULL",
        "email_pendente_hash"      => "VARCHAR(255) NULL",
        "email_pendente_expira"    => "DATETIME NULL",
        "email_pendente_tentativas" => "TINYINT UNSIGNED NOT NULL DEFAULT 0",
    ];

    $existentes = [];

    $res = $conn->query("SHOW COLUMNS FROM usuarios");

    while ($linha = $res->fetch_assoc()) {
        $existentes[$linha["Field"]] = true;
    }

    foreach ($colunas as $nome => $definicao) {
        if (!isset($existentes[$nome])) {
            $conn->query(
                "ALTER TABLE usuarios ADD COLUMN {$nome} {$definicao}"
            );
        }
    }

    $verificado = true;
}
