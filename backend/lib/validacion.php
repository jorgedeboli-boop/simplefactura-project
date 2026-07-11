<?php
// ============================================================================
// Simple Factura - Validacion de datos de entrada
// ============================================================================

/**
 * Comprueba que todos los campos requeridos existan y no esten vacios.
 * Si falta alguno, responde con error 400 y termina la ejecucion.
 */
function validar_campos_requeridos($datos, $campos) {
    $faltantes = array();
    foreach ($campos as $campo) {
        if (!isset($datos[$campo]) || $datos[$campo] === '' || $datos[$campo] === null) {
            $faltantes[] = $campo;
        }
    }
    if (count($faltantes) > 0) {
        responder_error('Faltan campos requeridos: ' . implode(', ', $faltantes), 400);
    }
}

/**
 * Valida formato basico de email.
 */
function validar_email($email) {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Limpia una cadena de texto de entrada (recorta espacios).
 */
function limpiar_texto($valor) {
    if (!is_string($valor)) {
        return $valor;
    }
    return trim($valor);
}

/**
 * Convierte a decimal seguro (evita null/strings raros en calculos).
 */
function a_decimal($valor, $default = 0.0) {
    if ($valor === null || $valor === '') {
        return $default;
    }
    return (float) $valor;
}
