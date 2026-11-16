<?php

require_once __DIR__ . "/../cors.php";
require_once __DIR__ . "/../conexao.php";
require_once __DIR__ . "/../helpers/colunas_perfil.php";

garantirColunasPerfil($conn);

if ($_SERVER["REQUEST_METHOD"] !== "GET") {
    http_response_code(405);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Método não permitido."
    ]);

    exit;
}

$motoristaId =
    intval(
        $_GET["motorista_id"] ?? 0
    );

if ($motoristaId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "motorista_id inválido."
    ]);

    exit;
}

// Retorna somente solicitações novas (dos últimos 15 minutos) que ainda
// estão esperando motorista. Depois que o motorista aceita, a solicitação
// sai da lista e não volta mais (nem se for cancelada ou concluída).
$stmt = $conn->prepare("
    SELECT
        s.id,
        s.cliente_id,
        s.motorista_id,
        s.veiculo_id,
        s.tipo_reboque,
        s.forma_pagamento,
        s.precisa_troco,
        s.troco_para,
        s.endereco,
        s.latitude,
        s.longitude,
        s.valor_estimado,
        s.descricao,
        s.status,
        s.created_at,

        c.nome AS cliente_nome,
        c.telefone AS cliente_telefone,
        c.foto_url AS cliente_foto,

        v.tipo AS veiculo_tipo,
        v.marca AS veiculo_marca,
        v.modelo AS veiculo_modelo,
        v.ano AS veiculo_ano,
        v.placa AS veiculo_placa,
        v.cor AS veiculo_cor

    FROM solicitacoes s

    INNER JOIN usuarios c
        ON c.id = s.cliente_id

    INNER JOIN veiculos v
        ON v.id = s.veiculo_id

    WHERE
        s.status = 'buscando'
        AND s.motorista_id IS NULL
        AND s.created_at >= (NOW() - INTERVAL 15 MINUTE)

    ORDER BY s.created_at DESC
");

$stmt->execute();

$resultado =
    $stmt->get_result();

$solicitacoes = [];

while (
    $s =
        $resultado->fetch_assoc()
) {
    $solicitacoes[] = [
        "id" =>
            intval($s["id"]),

        "cliente" => [
            "id" =>
                intval($s["cliente_id"]),
            "nome" =>
                $s["cliente_nome"],
            "telefone" =>
                $s["cliente_telefone"],
            "foto_url" =>
                $s["cliente_foto"]
        ],

        "veiculo" => [
            "id" =>
                intval($s["veiculo_id"]),
            "tipo" =>
                $s["veiculo_tipo"],
            "marca" =>
                $s["veiculo_marca"],
            "modelo" =>
                $s["veiculo_modelo"],
            "ano" =>
                intval($s["veiculo_ano"]),
            "placa" =>
                $s["veiculo_placa"],
            "cor" =>
                $s["veiculo_cor"]
        ],

        "motorista_id" =>
            $s["motorista_id"] === null
                ? null
                : intval(
                    $s["motorista_id"]
                ),

        "tipo_reboque" =>
            $s["tipo_reboque"],

        "forma_pagamento" =>
            $s["forma_pagamento"],

        "precisa_troco" =>
            intval(
                $s["precisa_troco"] ?? 0
            ),

        "troco_para" =>
            $s["troco_para"] === null
                ? null
                : floatval(
                    $s["troco_para"]
                ),

        "endereco" =>
            $s["endereco"],

        "latitude" =>
            floatval(
                $s["latitude"]
            ),

        "longitude" =>
            floatval(
                $s["longitude"]
            ),

        "valor_estimado" =>
            floatval(
                $s["valor_estimado"]
            ),

        "descricao" =>
            $s["descricao"],

        "status" =>
            $s["status"],

        "created_at" =>
            $s["created_at"]
    ];
}

echo json_encode([
    "sucesso" => true,
    "solicitacoes" => $solicitacoes
], JSON_UNESCAPED_UNICODE);
