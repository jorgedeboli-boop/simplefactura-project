<?php
// ============================================================================
// Simple Factura - Conexion a base de datos
// Estilo funcional puro (mysqli procedural, sin objetos/clases).
// ============================================================================

require_once __DIR__ . '/constantes.php';

/**
 * Conecta a la base de datos de CONTROL (listado de tenants + tokens_globales).
 * @return mysqli|resource conexion mysqli (procedural)
 */
function db_conectar_control() {
    try {
        $conexion = mysqli_connect(
            SF_CONTROL_DB_HOST,
            SF_CONTROL_DB_USER,
            SF_CONTROL_DB_PASS,
            SF_CONTROL_DB_NAME
        );
    } catch (mysqli_sql_exception $e) {
        $detalle = defined('SF_DEBUG') && SF_DEBUG ? $e->getMessage() : null;
        responder_error('No se pudo conectar a la base de datos de control', 500, $detalle);
    }

    if (!$conexion) {
        responder_error('No se pudo conectar a la base de datos de control', 500);
    }

    mysqli_set_charset($conexion, 'utf8mb4');
    return $conexion;
}

/**
 * Conecta a la base de datos de un tenant especifico usando sus credenciales
 * guardadas en la tabla tenants de la base de control.
 * @param array $tenant fila de la tabla tenants (db_host, db_name, db_usuario, db_password)
 * @return mysqli|resource conexion mysqli (procedural)
 */
function db_conectar_tenant($tenant) {
    try {
        $conexion = mysqli_connect(
            $tenant['db_host'],
            $tenant['db_usuario'],
            $tenant['db_password'],
            $tenant['db_name']
        );
    } catch (mysqli_sql_exception $e) {
        $detalle = defined('SF_DEBUG') && SF_DEBUG ? $e->getMessage() : null;
        responder_error('No se pudo conectar a la base de datos del cliente', 500, $detalle);
    }

    if (!$conexion) {
        responder_error('No se pudo conectar a la base de datos del cliente', 500);
    }

    mysqli_set_charset($conexion, 'utf8mb4');
    return $conexion;
}

/**
 * Ejecuta una consulta preparada y devuelve todas las filas como array asociativo.
 * @param mysqli $conexion
 * @param string $sql consulta con placeholders "?"
 * @param string $tipos cadena de tipos (s, i, d, b) para bind_param
 * @param array $parametros valores a enlazar
 * @return array filas de resultado
 */
function db_consultar($conexion, $sql, $tipos = '', $parametros = array()) {
    $stmt = mysqli_prepare($conexion, $sql);
    if (!$stmt) {
        responder_error('Error preparando consulta: ' . mysqli_error($conexion), 500);
    }

    if ($tipos !== '' && count($parametros) > 0) {
        mysqli_stmt_bind_param($stmt, $tipos, ...$parametros);
    }

    mysqli_stmt_execute($stmt);
    $resultado = mysqli_stmt_get_result($stmt);
    if ($resultado === false) {
        mysqli_stmt_close($stmt);
        responder_error(
            'El servidor no soporta consultas preparadas (requiere mysqlnd)',
            500
        );
    }

    $filas = array();
    while ($fila = mysqli_fetch_assoc($resultado)) {
        $filas[] = $fila;
    }
    mysqli_stmt_close($stmt);
    return $filas;
}

/**
 * Ejecuta una consulta preparada de escritura (INSERT/UPDATE/DELETE).
 * @return array ['id_insertado' => int, 'filas_afectadas' => int]
 */
function db_ejecutar($conexion, $sql, $tipos = '', $parametros = array()) {
    $stmt = mysqli_prepare($conexion, $sql);
    if (!$stmt) {
        responder_error('Error preparando consulta: ' . mysqli_error($conexion), 500);
    }

    if ($tipos !== '' && count($parametros) > 0) {
        mysqli_stmt_bind_param($stmt, $tipos, ...$parametros);
    }

    $ok = mysqli_stmt_execute($stmt);
    if (!$ok) {
        $error = mysqli_stmt_error($stmt);
        mysqli_stmt_close($stmt);
        responder_error('Error ejecutando consulta: ' . $error, 500);
    }

    $resultado = array(
        'id_insertado'    => mysqli_stmt_insert_id($stmt),
        'filas_afectadas' => mysqli_stmt_affected_rows($stmt),
    );
    mysqli_stmt_close($stmt);
    return $resultado;
}
