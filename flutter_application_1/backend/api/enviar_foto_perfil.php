<?php

header("Content-Type: application/json; charset=UTF-8");

require_once __DIR__ . "/../cors.php";
require_once __DIR__ . "/../conexao.php";
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

const TAMANHO_MAXIMO = 3 * 1024 * 1024; // 3 MB

$usuarioId = intval($_POST["usuario_id"] ?? 0);

if ($usuarioId <= 0) {
    responder(400, false, "usuario_id inválido.");
}

garantirColunasPerfil($conn);

$stmt = $conn->prepare("SELECT id, foto_url FROM usuarios WHERE id = ? LIMIT 1");
$stmt->bind_param("i", $usuarioId);
$stmt->execute();
$usuario = $stmt->get_result()->fetch_assoc();

if (!$usuario) {
    responder(404, false, "Usuário não encontrado.");
}

$pastaRelativa = "uploads/perfil";
$pastaAbsoluta = __DIR__ . "/../" . $pastaRelativa;

function apagarFotoAntiga(?string $relativo): void
{
    if (!$relativo) {
        return;
    }

    $nome = basename($relativo);

    if (!preg_match('/^u\d+_[a-f0-9]{16}\.(jpg|png|webp)$/', $nome)) {
        return;
    }

    $arquivo = __DIR__ . "/../uploads/perfil/" . $nome;

    if (is_file($arquivo)) {
        @unlink($arquivo);
    }
}

// ---- remover a foto
if (($_POST["remover"] ?? "") === "1") {
    apagarFotoAntiga($usuario["foto_url"]);

    $stmt = $conn->prepare("UPDATE usuarios SET foto_url = NULL WHERE id = ?");
    $stmt->bind_param("i", $usuarioId);
    $stmt->execute();

    responder(200, true, "Foto removida.", ["foto_url" => null]);
}

// ---- enviar nova foto
if (!isset($_FILES["foto"]) || $_FILES["foto"]["error"] !== UPLOAD_ERR_OK) {
    $erro = $_FILES["foto"]["error"] ?? UPLOAD_ERR_NO_FILE;

    if ($erro === UPLOAD_ERR_INI_SIZE || $erro === UPLOAD_ERR_FORM_SIZE) {
        responder(413, false, "A foto é grande demais. Máximo de 3 MB.");
    }

    responder(400, false, "Nenhuma foto foi enviada.");
}

$arquivo = $_FILES["foto"];

if ($arquivo["size"] > TAMANHO_MAXIMO) {
    responder(413, false, "A foto é grande demais. Máximo de 3 MB.");
}

// o tipo vem do CONTEÚDO do arquivo, não do nome nem do que o app diz
$finfo = new finfo(FILEINFO_MIME_TYPE);
$mime = $finfo->file($arquivo["tmp_name"]);

$extensoes = [
    "image/jpeg" => "jpg",
    "image/png"  => "png",
    "image/webp" => "webp",
];

if (!isset($extensoes[$mime]) || @getimagesize($arquivo["tmp_name"]) === false) {
    responder(415, false, "Envie uma imagem JPG, PNG ou WebP.");
}

if (!is_dir($pastaAbsoluta) && !mkdir($pastaAbsoluta, 0775, true)) {
    responder(500, false, "Não foi possível preparar a pasta de fotos.");
}

// nada de PHP rodando dentro da pasta de uploads
$htaccess = $pastaAbsoluta . "/.htaccess";

if (!is_file($htaccess)) {
    file_put_contents(
        $htaccess,
        "<FilesMatch \"\\.(php|phtml|php5)\$\">\n  Require all denied\n</FilesMatch>\n"
    );
}

$nomeArquivo = "u{$usuarioId}_" . bin2hex(random_bytes(8)) . "." . $extensoes[$mime];

if (!move_uploaded_file($arquivo["tmp_name"], $pastaAbsoluta . "/" . $nomeArquivo)) {
    responder(500, false, "Não foi possível salvar a foto.");
}

$novoCaminho = $pastaRelativa . "/" . $nomeArquivo;

$stmt = $conn->prepare("UPDATE usuarios SET foto_url = ? WHERE id = ?");
$stmt->bind_param("si", $novoCaminho, $usuarioId);

if (!$stmt->execute()) {
    @unlink($pastaAbsoluta . "/" . $nomeArquivo);
    responder(500, false, "Não foi possível atualizar o perfil.");
}

apagarFotoAntiga($usuario["foto_url"]);

responder(200, true, "Foto atualizada.", ["foto_url" => $novoCaminho]);
