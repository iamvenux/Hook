<?php

header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . "/../cors.php";
require_once __DIR__ . "/../conexao.php";
require_once __DIR__ . "/../email_service.php";
require_once __DIR__ . "/../helpers/colunas_perfil.php";

function responder(int $status, bool $sucesso, string $mensagem, array $extra = []): void
{
    http_response_code($status);

    echo json_encode(
        array_merge(["sucesso" => $sucesso, "mensagem" => $mensagem], $extra),
        JSON_UNESCAPED_UNICODE
    );

    exit;
}

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    responder(405, false, "Método não permitido.");
}

$dados = json_decode(file_get_contents("php://input"), true);

if (!is_array($dados)) {
    responder(400, false, "JSON inválido.");
}

$usuarioId = intval($dados["usuario_id"] ?? 0);
$codigo = trim($dados["codigo"] ?? "");

if ($usuarioId <= 0 || !preg_match('/^\d{6}$/', $codigo)) {
    responder(400, false, "Digite o código de 6 dígitos.");
}

garantirColunasPerfil($conn);

$stmt = $conn->prepare("
    SELECT email_pendente, email_pendente_hash, email_pendente_expira,
           email_pendente_tentativas
    FROM usuarios
    WHERE id = ?
    LIMIT 1
");
$stmt->bind_param("i", $usuarioId);
$stmt->execute();
$u = $stmt->get_result()->fetch_assoc();

if (!$u) {
    responder(404, false, "Usuário não encontrado.");
}

if ($u["email_pendente"] === null || $u["email_pendente_hash"] === null) {
    responder(400, false, "Nenhuma troca de e-mail pendente. Peça um novo código.");
}

if (intval($u["email_pendente_tentativas"]) >= 5) {
    responder(429, false, "Muitas tentativas. Peça um novo código.");
}

if (!codigoValido($codigo, $u["email_pendente_hash"], $u["email_pendente_expira"])) {
    $stmt = $conn->prepare(
        "UPDATE usuarios SET email_pendente_tentativas = email_pendente_tentativas + 1 WHERE id = ?"
    );
    $stmt->bind_param("i", $usuarioId);
    $stmt->execute();

    responder(400, false, "Código incorreto ou expirado.");
}

$novoEmail = $u["email_pendente"];

// confere de novo: alguém pode ter cadastrado esse e-mail nesse meio tempo
$stmt = $conn->prepare("SELECT id FROM usuarios WHERE email = ? AND id <> ? LIMIT 1");
$stmt->bind_param("si", $novoEmail, $usuarioId);
$stmt->execute();

if ($stmt->get_result()->num_rows > 0) {
    responder(409, false, "Este e-mail já está em uso por outra conta.");
}

$stmt = $conn->prepare("
    UPDATE usuarios
    SET email = ?,
        email_verificado = 1,
        email_pendente = NULL,
        email_pendente_hash = NULL,
        email_pendente_expira = NULL,
        email_pendente_tentativas = 0
    WHERE id = ?
");
$stmt->bind_param("si", $novoEmail, $usuarioId);

if (!$stmt->execute()) {
    responder(500, false, "Não foi possível salvar o novo e-mail.");
}

responder(200, true, "E-mail atualizado com sucesso.", [
    "usuario" => ["id" => $usuarioId, "email" => $novoEmail]
]);
