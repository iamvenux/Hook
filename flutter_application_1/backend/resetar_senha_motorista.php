<?php

require_once __DIR__ . "/conexao.php";

$email = "motorista@hook.com";
$novaSenha = "123456";

$senhaHash = password_hash($novaSenha, PASSWORD_DEFAULT);

$stmt = $conn->prepare("
    UPDATE usuarios
    SET senha_hash = ?
    WHERE email = ?
      AND tipo = 'motorista'
");

$stmt->bind_param(
    "ss",
    $senhaHash,
    $email
);

$stmt->execute();

if ($stmt->affected_rows > 0) {
    echo "Senha do motorista atualizada com sucesso.";
} else {
    echo "Motorista não encontrado ou senha já estava igual.";
}