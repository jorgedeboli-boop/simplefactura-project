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
 * Texto opcional: cadena vacia / null -> null; resto limpio.
 */
function contacto_texto_opcional($valor) {
    if ($valor === null) {
        return null;
    }
    $texto = limpiar_texto(is_string($valor) ? $valor : (string) $valor);
    return $texto === '' ? null : $texto;
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

/**
 * Valida y normaliza un color hexadecimal (#RGB o #RRGGBB).
 */
function sf_normalizar_color_hex($color) {
    $color = trim((string) $color);
    if (!preg_match('/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/', $color)) {
        return null;
    }
    if (strlen($color) === 4) {
        $r = $color[1];
        $g = $color[2];
        $b = $color[3];
        return '#' . $r . $r . $g . $g . $b . $b;
    }
    return strtolower($color);
}
