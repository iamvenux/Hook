<?php

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require_once __DIR__ . "/vendor/autoload.php";

function enviarEmailHook(
    string $destinatario,
    string $nome,
    string $assunto,
    string $html,
    string $texto
): void {
    $config = require __DIR__ . "/config_email.php";

    $mail = new PHPMailer(true);

    try {
        $mail->isSMTP();

        $mail->Host = $config["host"];
        $mail->SMTPAuth = true;
        $mail->Username = $config["username"];
        $mail->Password = $config["password"];

        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port = $config["port"];

        $mail->CharSet = "UTF-8";

        $mail->setFrom(
            $config["from_email"],
            $config["from_name"]
        );

        $mail->addAddress(
            $destinatario,
            $nome
        );

        $mail->isHTML(true);

        $mail->Subject = $assunto;
        $mail->Body = $html;
        $mail->AltBody = $texto;

        $mail->send();
    } catch (Exception $e) {
        throw new RuntimeException(
            "Não foi possível enviar o e-mail: " . $mail->ErrorInfo
        );
    }
}

function gerarCodigo6Digitos(): string
{
    return str_pad(
        (string) random_int(0, 999999),
        6,
        "0",
        STR_PAD_LEFT
    );
}

function criarHashCodigo(string $codigo): string
{
    return password_hash(
        $codigo,
        PASSWORD_DEFAULT
    );
}

function codigoValido(
    string $codigo,
    ?string $hash,
    ?string $expira
): bool {
    if ($hash === null || $expira === null) {
        return false;
    }

    $agora = new DateTime();
    $limite = new DateTime($expira);

    if ($agora > $limite) {
        return false;
    }

    return password_verify(
        $codigo,
        $hash
    );
}

function htmlCodigo(
    string $nome,
    string $codigo,
    string $titulo
): string {
    $nomeSeguro = htmlspecialchars(
        $nome,
        ENT_QUOTES,
        "UTF-8"
    );

    $codigoSeguro = htmlspecialchars(
        $codigo,
        ENT_QUOTES,
        "UTF-8"
    );

    return "
        <div style='font-family:Arial,sans-serif;max-width:520px;margin:auto'>
            <h2 style='color:#1A7EF5'>Hook</h2>

            <p>Olá, {$nomeSeguro}!</p>

            <p>{$titulo}</p>

            <div style='
                font-size:32px;
                font-weight:700;
                letter-spacing:8px;
                padding:18px;
                background:#f3f6fa;
                border-radius:12px;
                text-align:center;
                margin:24px 0;
            '>
                {$codigoSeguro}
            </div>

            <p>
                Este código expira em
                <strong>10 minutos</strong>.
            </p>

            <p style='color:#777;font-size:13px'>
                Se você não solicitou esta ação,
                ignore este e-mail.
            </p>
        </div>
    ";
}
