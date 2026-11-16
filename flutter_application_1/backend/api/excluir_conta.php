<?php

header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . "/../cors.php";
require_once __DIR__ . "/../conexao.php";

/*
|--------------------------------------------------------------------------
| EXCLUSÃO DE CONTA
|--------------------------------------------------------------------------
|
| As solicitações apontam para o cliente e para o motorista, e o
| histórico da outra parte precisa continuar existindo. Por isso a linha
| não é apagada: os dados pessoais são anonimizados, o login deixa de
| funcionar, os veículos saem da lista e a foto é removida do servidor.
|
*/

function responder($codigo, $sucesso, $mensagem) {
    http_response_code($codigo);

    echo json_encode(
        ["sucesso" => $sucesso, "mensagem" => $mensagem],
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
$senha     = (string)($dados["senha"] ?? "");

if ($usuarioId <= 0 || $senha === "") {
    responder(400, false, "Informe sua senha para excluir a conta.");
}

// ============================================================
// CONFERE A SENHA
// ============================================================

$stmt = $conn->prepare(
    "SELECT id, senha_hash, tipo FROM usuarios WHERE id = ? LIMIT 1"
);

$stmt->bind_param("i", $usuarioId);
$stmt->execute();

$usuario = $stmt->get_result()->fetch_assoc();

if (!$usuario) {
    responder(404, false, "Usuário não encontrado.");
}

if (!password_verify($senha, (string)$usuario["senha_hash"])) {
    responder(401, false, "Senha incorreta.");
}

// ============================================================
// COLUNAS QUE EXISTEM NESTE BANCO
// ============================================================
// O banco pode estar em versões diferentes (com ou sem foto, código de
// verificação, etc.), então só limpamos as colunas que realmente existem.

function colunasDaTabela(mysqli $conn, $tabela) {
    $colunas = [];

    $res = $conn->query("SHOW COLUMNS FROM `" . $tabela . "`");

    if ($res) {
        while ($linha = $res->fetch_assoc()) {
            $colunas[$linha["Field"]] = true;
        }
    }

    return $colunas;
}

function tabelaExiste(mysqli $conn, $tabela) {
    $res = $conn->query("SHOW TABLES LIKE '" . $conn->real_escape_string($tabela) . "'");

    return $res && $res->num_rows > 0;
}

$colunas = colunasDaTabela($conn, "usuarios");

// Foto antiga: apagada do disco depois que o banco for atualizado.
$fotoAntiga = null;

if (isset($colunas["foto_url"])) {
    $stmt = $conn->prepare("SELECT foto_url FROM usuarios WHERE id = ? LIMIT 1");
    $stmt->bind_param("i", $usuarioId);
    $stmt->execute();

    $fotoAntiga = $stmt->get_result()->fetch_assoc()["foto_url"] ?? null;
}

// ============================================================
// ANONIMIZA
// ============================================================

$conn->begin_transaction();

try {
    // E-mail único e inválido: libera o e-mail original para novo cadastro.
    $emailAnonimo = "excluido_" . $usuarioId . "_" . time() . "@hook.invalid";

    // Senha aleatória: ninguém entra mais nesta conta.
    $senhaAnonima = password_hash(
        bin2hex(random_bytes(16)),
        PASSWORD_DEFAULT
    );

    $campos  = ["nome = ?", "email = ?", "senha_hash = ?"];
    $tipos   = "sss";
    $valores = ["Conta excluída", $emailAnonimo, $senhaAnonima];

    // Colunas opcionais, limpas só se existirem nesta versão do banco.
    $paraNulo = [
        "telefone",
        "foto_url",
        "placa_guincho",
        "tipo_guincho",
        "latitude_atual",
        "longitude_atual",
        "api_token",
        "codigo_verificacao_hash",
        "codigo_verificacao_expira",
        "codigo_recuperacao_hash",
        "codigo_recuperacao_expira",
        "email_pendente",
        "email_pendente_hash",
        "email_pendente_expira",
    ];

    foreach ($paraNulo as $coluna) {
        if (isset($colunas[$coluna])) {
            $campos[] = "`" . $coluna . "` = NULL";
        }
    }

    foreach (["email_verificado", "disponivel", "email_pendente_tentativas"] as $coluna) {
        if (isset($colunas[$coluna])) {
            $campos[] = "`" . $coluna . "` = 0";
        }
    }

    $tipos .= "i";
    $valores[] = $usuarioId;

    $stmt = $conn->prepare(
        "UPDATE usuarios SET " . implode(", ", $campos) . " WHERE id = ?"
    );

    $stmt->bind_param($tipos, ...$valores);

    if (!$stmt->execute()) {
        throw new RuntimeException($stmt->error);
    }

    // Atendimentos em aberto são cancelados (dos dois lados).
    $stmt = $conn->prepare(
        "UPDATE solicitacoes
            SET status = 'cancelado'
          WHERE (cliente_id = ? OR motorista_id = ?)
            AND status NOT IN ('concluido', 'cancelado')"
    );

    $stmt->bind_param("ii", $usuarioId, $usuarioId);

    if (!$stmt->execute()) {
        throw new RuntimeException($stmt->error);
    }

    // Veículos saem da lista (exclusão lógica, como em excluir_veiculo.php).
    $colunasVeiculos = colunasDaTabela($conn, "veiculos");

    if (isset($colunasVeiculos["ativo"])) {
        $sql = isset($colunasVeiculos["padrao"])
            ? "UPDATE veiculos SET ativo = 0, padrao = 0 WHERE usuario_id = ?"
            : "UPDATE veiculos SET ativo = 0 WHERE usuario_id = ?";

        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $usuarioId);

        if (!$stmt->execute()) {
            throw new RuntimeException($stmt->error);
        }
    }

    // Endereços salvos no banco, se este projeto já tiver a tabela.
    if (tabelaExiste($conn, "enderecos")) {
        $stmt = $conn->prepare("DELETE FROM enderecos WHERE usuario_id = ?");
        $stmt->bind_param("i", $usuarioId);

        if (!$stmt->execute()) {
            throw new RuntimeException($stmt->error);
        }
    }

    $conn->commit();
} catch (Throwable $e) {
    $conn->rollback();

    error_log("excluir_conta: " . $e->getMessage());

    responder(500, false, "Não foi possível excluir a conta.");
}

// ============================================================
// FOTO DE PERFIL NO SERVIDOR
// ============================================================

if (is_string($fotoAntiga) && $fotoAntiga !== "") {
    $nome = basename($fotoAntiga);

    if (preg_match('/^u\d+_[a-f0-9]{16}\.(jpg|png|webp)$/', $nome)) {
        $caminho = __DIR__ . "/../uploads/perfil/" . $nome;

        if (is_file($caminho)) {
            @unlink($caminho);
        }
    }
}

responder(200, true, "Conta excluída. Sentiremos sua falta!");
