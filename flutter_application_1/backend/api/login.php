<?php

header("Content-Type: application/json; charset=UTF-8");

require_once "../conexao.php";

$dados = json_decode(file_get_contents("php://input"), true);

$email = trim($dados["email"] ?? "");
$senha = $dados["senha"] ?? "";

if ($email === "" || $senha === "") {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe email e senha."
    ]);

    exit;
}

$sql = "
    SELECT
        id,
        nome,
        email,
        senha_hash,
        tipo,
        telefone,
        placa_guincho,
        disponivel,
        latitude_atual,
        longitude_atual,
        api_token
    FROM usuarios
    WHERE email = ?
    LIMIT 1
";

$stmt = $conn->prepare($sql);

if (!$stmt) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Erro ao preparar consulta."
    ]);

    exit;
}

$stmt->bind_param("s", $email);
$stmt->execute();

$resultado = $stmt->get_result();

if ($resultado->num_rows === 0) {
    http_response_code(401);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Email ou senha incorretos."
    ]);

    exit;
}

$usuario = $resultado->fetch_assoc();

if (!password_verify($senha, $usuario["senha_hash"])) {
    http_response_code(401);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Email ou senha incorretos."
    ]);

    exit;
}

if (empty($usuario["api_token"])) {
    $token = bin2hex(random_bytes(32));

    $update = $conn->prepare("
        UPDATE usuarios
        SET api_token = ?
        WHERE id = ?
    ");

    $update->bind_param(
        "si",
        $token,
        $usuario["id"]
    );

    $update->execute();

    $usuario["api_token"] = $token;
}

unset($usuario["senha_hash"]);

echo json_encode([
    "sucesso" => true,
    "mensagem" => "Login realizado com sucesso.",
    "usuario" => $usuario
]);