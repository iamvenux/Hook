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
$novoEmail = strtolower(trim($dados["novo_email"] ?? ""));

if ($usuarioId <= 0) {
    responder(400, false, "usuario_id inválido.");
}

if (!filter_var($novoEmail, FILTER_VALIDATE_EMAIL) || strlen($novoEmail) > 150) {
    responder(400, false, "Informe um e-mail válido.");
}

garantirColunasPerfil($conn);

// ---- usuário atual
$stmt = $conn->prepare(
    "SELECT id, nome, email, email_pendente_expira FROM usuarios WHERE id = ? LIMIT 1"
);
$stmt->bind_param("i", $usuarioId);
$stmt->execute();
$usuario = $stmt->get_result()->fetch_assoc();

if (!$usuario) {
    responder(404, false, "Usuário não encontrado.");
}

if (strtolower($usuario["email"]) === $novoEmail) {
    responder(400, false, "Este já é o seu e-mail atual.");
}

// ---- não pode estar em uso por outra conta
$stmt = $conn->prepare(
    "SELECT id FROM usuarios WHERE email = ? AND id <> ? LIMIT 1"
);
$stmt->bind_param("si", $novoEmail, $usuarioId);
$stmt->execute();

if ($stmt->get_result()->num_rows > 0) {
    responder(409, false, "Este e-mail já está em uso por outra conta.");
}

// ---- evita reenvio em sequência (mínimo 30 s entre pedidos)
if ($usuario["email_pendente_expira"] !== null) {
    $enviadoEm = strtotime($usuario["email_pendente_expira"]) - 600;

    if (time() - $enviadoEm < 30) {
        responder(429, false, "Aguarde alguns segundos antes de pedir outro código.");
    }
}

// ---- gera e guarda o código (só o hash vai para o banco)
$codigo = gerarCodigo6Digitos();
$hash = criarHashCodigo($codigo);
$expira = date("Y-m-d H:i:s", time() + 600);

$stmt = $conn->prepare("
    UPDATE usuarios
    SET email_pendente = ?,
        email_pendente_hash = ?,
        email_pendente_expira = ?,
        email_pendente_tentativas = 0
    WHERE id = ?
");
$stmt->bind_param("sssi", $novoEmail, $hash, $expira, $usuarioId);
$stmt->execute();

// ---- envia para o NOVO endereço
try {
    enviarEmailHook(
        $novoEmail,
        $usuario["nome"],
        "Confirme seu novo e-mail - Hook",
        htmlCodigo(
            $usuario["nome"],
            $codigo,
            "Use este código para confirmar a troca do e-mail da sua conta."
        ),
        "Seu código para confirmar o novo e-mail no Hook é: {$codigo}. Ele expira em 10 minutos."
    );
} catch (Throwable $e) {
    error_log("solicitar_troca_email: " . $e->getMessage());

    $stmt = $conn->prepare("
        UPDATE usuarios
        SET email_pendente = NULL, email_pendente_hash = NULL, email_pendente_expira = NULL
        WHERE id = ?
    ");
    $stmt->bind_param("i", $usuarioId);
    $stmt->execute();

    responder(500, false, "Não foi possível enviar o código. Tente novamente em instantes.");
}

responder(200, true, "Enviamos um código para {$novoEmail}.");
