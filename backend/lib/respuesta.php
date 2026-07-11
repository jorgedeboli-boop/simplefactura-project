<?php
// ============================================================================
// Simple Factura - Helpers de respuesta HTTP en JSON
// ============================================================================

/**
 * Envia una respuesta JSON de exito y termina la ejecucion.
 */
function responder_json($datos, $codigo_http = 200) {
    http_response_code($codigo_http);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(array(
        'ok'   => true,
        'data' => $datos,
    ), JSON_UNESCAPED_UNICODE);
    exit;
}

/**
 * Envia una respuesta JSON de error y termina la ejecucion.
 */
function responder_error($mensaje, $codigo_http = 400, $detalles = null) {
    http_response_code($codigo_http);
    header('Content-Type: application/json; charset=utf-8');
    $payload = array(
        'ok'    => false,
        'error' => $mensaje,
    );
    if ($detalles !== null && defined('SF_DEBUG') && SF_DEBUG) {
        $payload['detalles'] = $detalles;
    }
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit;
}

/**
 * Lee y decodifica el body JSON de la peticion actual.
 */
function leer_json_entrada() {
    $crudo = file_get_contents('php://input');
    if ($crudo === false || $crudo === '') {
        return array();
    }
    $datos = json_decode($crudo, true);
    if ($datos === null) {
        responder_error('El cuerpo de la peticion no es JSON valido', 400);
    }
    return $datos;
}
