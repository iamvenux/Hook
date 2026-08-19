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

$tipo = trim(
    $dados["tipo"] ?? ""
);

$marca = trim(
    $dados["marca"] ?? ""
);

$modelo = trim(
    $dados["modelo"] ?? ""
);

$ano = intval(
    $dados["ano"] ?? 0
);

$placa = strtoupper(
    trim(
        $dados["placa"] ?? ""
    )
);

$placa = str_replace(
    ["-", " "],
    "",
    $placa
);

$cor = trim(
    $dados["cor"] ?? ""
);

if ($usuarioId <= 0 || $veiculoId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Usuário ou veículo inválido."
    ]);

    exit;
}

if (!in_array(
    $tipo,
    ["Carro", "Moto", "SUV"],
    true
)) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Tipo de veículo inválido."
    ]);

    exit;
}

if (
    $marca === "" ||
    $modelo === "" ||
    $ano <= 0 ||
    $placa === "" ||
    $cor === ""
) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Preencha todos os dados do veículo."
    ]);

    exit;
}

// Confirma que o veículo pertence ao cliente.
$stmt = $conn->prepare("
    SELECT id
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

// Não permite placa duplicada em outro veículo.
$stmt = $conn->prepare("
    SELECT id
    FROM veiculos
    WHERE placa = ?
      AND id <> ?
    LIMIT 1
");

$stmt->bind_param(
    "si",
    $placa,
    $veiculoId
);

$stmt->execute();

$resultado = $stmt->get_result();

if ($resultado->num_rows > 0) {
    http_response_code(409);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Já existe outro veículo com essa placa."
    ]);

    exit;
}

$stmt = $conn->prepare("
    UPDATE veiculos
    SET
        tipo = ?,
        marca = ?,
        modelo = ?,
        ano = ?,
        placa = ?,
        cor = ?
    WHERE id = ?
      AND usuario_id = ?
");

$stmt->bind_param(
    "sssissii",
    $tipo,
    $marca,
    $modelo,
    $ano,
    $placa,
    $cor,
    $veiculoId,
    $usuarioId
);

if (!$stmt->execute()) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Erro ao atualizar veículo."
    ]);

    exit;
}

echo json_encode([
    "sucesso" => true,
    "mensagem" => "Veículo atualizado com sucesso."
], JSON_UNESCAPED_UNICODE);