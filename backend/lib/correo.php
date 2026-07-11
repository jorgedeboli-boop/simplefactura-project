<?php
// ============================================================================
// Simple Factura - Envio de correo basico (mail() del servidor)
// ============================================================================

/**
 * Envia un correo de texto plano.
 *
 * @return bool true si mail() acepto el envio
 */
function correo_enviar($destinatario, $asunto, $cuerpo) {
    $remitente = SF_CORREO_REMITENTE;
    $cabeceras = array(
        'From: Simple Factura <' . $remitente . '>',
        'Reply-To: ' . $remitente,
        'MIME-Version: 1.0',
        'Content-Type: text/plain; charset=UTF-8',
    );

    return mail($destinatario, $asunto, $cuerpo, implode("\r\n", $cabeceras));
}

/**
 * Construye el cuerpo del correo de recuperacion de contraseña.
 */
function correo_cuerpo_recuperacion_password($enlace) {
    return "Hola,\n\n"
        . "Hemos recibido una solicitud para restablecer tu contraseña en Simple Factura.\n\n"
        . "Si fuiste tu, abre este enlace (valido durante " . SF_RECUPERACION_HORAS_EXPIRACION . " horas):\n"
        . $enlace . "\n\n"
        . "Si no solicitaste este cambio, puedes ignorar este mensaje.\n\n"
        . "Simple Factura\n";
}
