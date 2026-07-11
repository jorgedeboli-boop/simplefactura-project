<?php
// ============================================================================
// Simple Factura - Autenticacion (token opaco, sin dependencias externas)
// Estilo funcional puro.
// ============================================================================

/**
 * Genera un token aleatorio de 64 caracteres hexadecimales.
 */
function auth_generar_token() {
    return bin2hex(random_bytes(32));
}

/**
 * Lee el token de la peticion: Authorization, X-Auth-Token o ?token=
 * (fallbacks para hostings que no pasan Authorization a PHP).
 */
function auth_leer_token_cabecera() {
    $valor = null;

    if (function_exists('getallheaders')) {
        foreach (getallheaders() as $nombre => $val) {
            if (strtolower($nombre) === 'authorization') {
                $valor = $val;
                break;
            }
        }
    }

    if ($valor === null && function_exists('apache_request_headers')) {
        foreach (apache_request_headers() as $nombre => $val) {
            if (strtolower($nombre) === 'authorization') {
                $valor = $val;
                break;
            }
        }
    }

    if ($valor === null && isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $valor = $_SERVER['HTTP_AUTHORIZATION'];
    }
    if ($valor === null && isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $valor = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    }
    if ($valor === null && isset($_SERVER['HTTP_X_AUTH_TOKEN'])) {
        return trim($_SERVER['HTTP_X_AUTH_TOKEN']);
    }
    if ($valor === null && isset($_GET['token']) && $_GET['token'] !== '') {
        return trim($_GET['token']);
    }
    if ($valor === null) {
        return null;
    }

    if (stripos($valor, 'Bearer ') === 0) {
        return trim(substr($valor, 7));
    }
    return trim($valor);
}

/**
 * Valida el token de la peticion actual contra simplefactura_control.tokens_globales.
 * Si es valido, devuelve un array con la info del tenant y del usuario.
 * Si no es valido, responde con error 401 y termina la ejecucion.
 *
 * @return array [
 *   'tenant'      => fila de la tabla tenants,
 *   'usuario_id'  => id del usuario dentro de la BD del tenant,
 *   'token'       => token recibido,
 * ]
 */
function auth_requerir_sesion() {
    $token = auth_leer_token_cabecera();
    if (!$token) {
        responder_error('Falta el token de autenticacion (Authorization: Bearer ...)', 401);
    }

    $conexionControl = db_conectar_control();

    $filas = db_consultar(
        $conexionControl,
        "SELECT tg.usuario_id, tg.fecha_expiracion, t.*
         FROM tokens_globales tg
         INNER JOIN tenants t ON t.id = tg.tenant_id
         WHERE tg.token = ?
         LIMIT 1",
        's',
        array($token)
    );

    if (count($filas) === 0) {
        responder_error('Token invalido', 401);
    }

    $fila = $filas[0];

    if (strtotime($fila['fecha_expiracion']) < time()) {
        responder_error('La sesion ha expirado, vuelve a iniciar sesion', 401);
    }

    if ($fila['estado'] === 'suspendido' || $fila['estado'] === 'baja') {
        responder_error('La cuenta de esta empresa no esta activa', 403);
    }

    return array(
        'tenant'     => $fila,
        'usuario_id' => (int) $fila['usuario_id'],
        'token'      => $token,
    );
}

/**
 * Comprueba si el usuario autenticado tiene un permiso concreto.
 * Debe llamarse con una conexion YA abierta a la base del tenant.
 */
function auth_tiene_permiso($conexionTenant, $usuarioId, $codigoPermiso) {
    $filas = db_consultar(
        $conexionTenant,
        "SELECT COUNT(*) AS total
         FROM usuarios u
         INNER JOIN roles_permisos rp ON rp.role_id = u.role_id
         INNER JOIN permisos p ON p.id = rp.permiso_id
         WHERE u.id = ? AND p.codigo = ?",
        'is',
        array($usuarioId, $codigoPermiso)
    );

    return count($filas) > 0 && (int) $filas[0]['total'] > 0;
}

/**
 * Exige que el usuario autenticado tenga el permiso indicado.
 * Si no lo tiene, responde con error 403 y termina la ejecucion.
 */
function auth_requerir_permiso($conexionTenant, $usuarioId, $codigoPermiso) {
    if (!auth_tiene_permiso($conexionTenant, $usuarioId, $codigoPermiso)) {
        responder_error('No tienes permiso para realizar esta accion', 403);
    }
}
