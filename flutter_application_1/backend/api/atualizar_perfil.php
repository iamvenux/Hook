<?php

header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . "/../cors.php";
require_once __DIR__ . "/../conexao.php";

if ($_SERVER["REQUEST_METHOD"] !== "POST" &&
    $_SERVER["REQUEST_METHOD"] !== "PUT") {
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

// ============================================================
// DADOS RECEBIDOS
// ============================================================

$usuarioId = intval($dados["usuario_id"] ?? 0);

$nome = trim($dados["nome"] ?? "");

// Só dígitos, igual ao cadastro (criar_conta.php).
$telefone = preg_replace(
    "/\\D/",
    "",
    (string)($dados["telefone"] ?? "")
);

// O e-mail NÃO é alterado aqui: a troca exige código enviado ao novo
// endereço (solicitar_troca_email.php + confirmar_troca_email.php).
$email = "";

// Troca de senha é opcional: só é feita se o cliente mandar
// os dois campos preenchidos.
$senhaAtual = trim($dados["senha_atual"] ?? "");
$novaSenha  = trim($dados["nova_senha"] ?? "");

$querTrocarSenha =
    $senhaAtual !== "" || $novaSenha !== "";

// ============================================================
// VALIDAÇÃO
// ============================================================

if ($usuarioId <= 0) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "usuario_id inválido."
    ]);

    exit;
}

if ($nome === "") {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "O nome não pode ficar em branco."
    ]);

    exit;
}

if (mb_strlen($nome) > 150) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Nome muito longo."
    ]);

    exit;
}

if ($telefone !== "" &&
    (strlen($telefone) < 10 || strlen($telefone) > 11)) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Informe um telefone válido com DDD."
    ]);

    exit;
}

if ($email !== "" && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "E-mail inválido."
    ]);

    exit;
}

if ($querTrocarSenha) {
    if ($senhaAtual === "" || $novaSenha === "") {
        http_response_code(400);

        echo json_encode([
            "sucesso" => false,
            "mensagem" => "Para trocar a senha, informe a senha atual e a nova senha."
        ]);

        exit;
    }

    if (mb_strlen($novaSenha) < 6) {
        http_response_code(400);

        echo json_encode([
            "sucesso" => false,
            "mensagem" => "A nova senha deve possuir pelo menos 6 caracteres."
        ]);

        exit;
    }

    // bcrypt ignora tudo depois de 72 bytes.
    if (strlen($novaSenha) > 72) {
        http_response_code(400);

        echo json_encode([
            "sucesso" => false,
            "mensagem" => "A nova senha pode ter no máximo 72 caracteres."
        ]);

        exit;
    }

    if ($novaSenha === $senhaAtual) {
        http_response_code(400);

        echo json_encode([
            "sucesso" => false,
            "mensagem" => "A nova senha deve ser diferente da atual."
        ]);

        exit;
    }
}

// ============================================================
// BUSCA USUÁRIO
// ============================================================

$stmt = $conn->prepare(
    "SELECT id, email, senha_hash FROM usuarios WHERE id = ? LIMIT 1"
);

$stmt->bind_param("i", $usuarioId);
$stmt->execute();

$resultado = $stmt->get_result();

if ($resultado->num_rows === 0) {
    http_response_code(404);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Usuário não encontrado."
    ]);

    exit;
}

$usuario = $resultado->fetch_assoc();

// ============================================================
// SE FOR TROCAR SENHA, CONFERE A SENHA ATUAL
// ============================================================

$novoHash = null;

if ($querTrocarSenha) {
    if (!password_verify($senhaAtual, $usuario["senha_hash"])) {
        http_response_code(403);

        echo json_encode([
            "sucesso" => false,
            "mensagem" => "Senha atual incorreta."
        ]);

        exit;
    }

    $novoHash = password_hash($novaSenha, PASSWORD_DEFAULT);
}

// ============================================================
// E-MAIL: NÃO PODE ESTAR EM USO POR OUTRA CONTA
// ============================================================

if ($email !== "") {
    $stmt = $conn->prepare(
        "SELECT id FROM usuarios WHERE email = ? AND id <> ? LIMIT 1"
    );

    $stmt->bind_param("si", $email, $usuarioId);
    $stmt->execute();

    if ($stmt->get_result()->num_rows > 0) {
        http_response_code(409);

        echo json_encode([
            "sucesso" => false,
            "mensagem" => "Este e-mail já está em uso por outra conta."
        ]);

        exit;
    }
}

// ============================================================
// ATUALIZA
// ============================================================

$campos = ["nome = ?", "telefone = ?"];
$tipos = "ss";
$valores = [$nome, $telefone];

if ($novoHash !== null) {
    $campos[] = "senha_hash = ?";
    $tipos .= "s";
    $valores[] = $novoHash;
}

if ($email !== "") {
    $campos[] = "email = ?";
    $tipos .= "s";
    $valores[] = $email;
}

$tipos .= "i";
$valores[] = $usuarioId;

$stmt = $conn->prepare(
    "UPDATE usuarios SET " . implode(", ", $campos) . " WHERE id = ?"
);

$stmt->bind_param($tipos, ...$valores);

if (!$stmt->execute()) {
    http_response_code(500);

    echo json_encode([
        "sucesso" => false,
        "mensagem" => "Erro ao atualizar perfil.",
        "erro" => $stmt->error
    ]);

    exit;
}

// ============================================================
// RESPOSTA
// ============================================================

echo json_encode([
    "sucesso" => true,
    "mensagem" => $querTrocarSenha
        ? "Perfil e senha atualizados com sucesso."
        : "Perfil atualizado com sucesso.",
    "usuario" => [
        "id" => $usuarioId,
        "nome" => $nome,
        "telefone" => $telefone,
        "email" => $email !== "" ? $email : $usuario["email"]
    ]
], JSON_UNESCAPED_UNICODE);
