<?php

header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . "/../cors.php";
require_once __DIR__ . "/../conexao.php";

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    http_response_code(405);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Método não permitido."
    ]);

    exit;
}

$dados = json_decode(
    file_get_contents("php://input"),
    true
);

if (!is_array($dados)) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "JSON inválido."
    ]);

    exit;
}

$usuarioId = intval(
    $dados["usuario_id"] ?? 0
);

$veiculoId = intval(
    $dados["veiculo_id"] ?? 0
);

if ($usuarioId <= 0 || $veiculoId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Dados inválidos."
    ]);

    exit;
}

// ============================================================
// VERIFICA O VEÍCULO
// ============================================================

$stmt = $conn->prepare("
    SELECT
        id,
        padrao,
        ativo
    FROM veiculos
    WHERE id = ?
      AND usuario_id = ?
    LIMIT 1
");

$stmt->bind_param(
    "ii",
    $veiculoId,
    $usuarioId
);

$stmt->execute();

$resultado = $stmt->get_result();

if ($resultado->num_rows === 0) {
    http_response_code(404);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Veículo não encontrado."
    ]);

    exit;
}

$veiculo = $resultado->fetch_assoc();

if (intval($veiculo["ativo"]) === 0) {
    http_response_code(409);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Este veículo já foi excluído."
    ]);

    exit;
}

$eraPadrao =
    intval($veiculo["padrao"]) === 1;

// ============================================================
// EXCLUSÃO LÓGICA
// ============================================================

$conn->begin_transaction();

try {

    $stmt = $conn->prepare("
        UPDATE veiculos
        SET
            ativo = 0,
            padrao = 0
        WHERE id = ?
          AND usuario_id = ?
    ");

    $stmt->bind_param(
        "ii",
        $veiculoId,
        $usuarioId
    );

    $stmt->execute();

    // ========================================================
    // SE ERA PADRÃO, ESCOLHE OUTRO VEÍCULO ATIVO
    // ========================================================

    if ($eraPadrao) {

        $stmt = $conn->prepare("
            SELECT id
            FROM veiculos
            WHERE usuario_id = ?
              AND ativo = 1
            ORDER BY id ASC
            LIMIT 1
        ");

        $stmt->bind_param(
            "i",
            $usuarioId
        );

        $stmt->execute();

        $resultado = $stmt->get_result();

        if ($resultado->num_rows > 0) {

            $novoPadrao =
                $resultado->fetch_assoc();

            $novoPadraoId =
                intval(
                    $novoPadrao["id"]
                );

            $stmt = $conn->prepare("
                UPDATE veiculos
                SET padrao = 1
                WHERE id = ?
                  AND usuario_id = ?
                  AND ativo = 1
            ");

            $stmt->bind_param(
                "ii",
                $novoPadraoId,
                $usuarioId
            );

            $stmt->execute();
        }
    }

    $conn->commit();

    echo json_encode([
        "sucesso" => true,
        "mensagem" => "Veículo excluído com sucesso."
    ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {

    $conn->rollback();

    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Não foi possível excluir o veículo."
    ], JSON_UNESCAPED_UNICODE);
}