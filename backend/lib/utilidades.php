<?php
// ============================================================================
// Simple Factura - Utilidades generales
// ============================================================================

/**
 * Genera el siguiente numero correlativo para un tipo de documento
 * (presupuesto, factura, factura_simplificada, factura_rectificativa),
 * de forma atomica y sin huecos, tal como exige la normativa de la mayoria
 * de los paises soportados.
 *
 * @return array ['numero' => '000123', 'serie' => 'A', 'anio' => 2026]
 */
function generar_numero_documento($conexionTenant, $tipoDocumento, $serie = 'A') {
    $anio = (int) date('Y');

    // Asegura que exista la fila de la serie para este anio (idempotente).
    mysqli_query($conexionTenant, 'START TRANSACTION');

    db_ejecutar(
        $conexionTenant,
        "INSERT INTO series_numeracion (tipo_documento, serie, anio, ultimo_numero)
         VALUES (?, ?, ?, 0)
         ON DUPLICATE KEY UPDATE ultimo_numero = ultimo_numero",
        'ssi',
        array($tipoDocumento, $serie, $anio)
    );

    // Bloquea la fila e incrementa el correlativo.
    db_consultar(
        $conexionTenant,
        "SELECT id FROM series_numeracion
         WHERE tipo_documento = ? AND serie = ? AND anio = ?
         FOR UPDATE",
        'ssi',
        array($tipoDocumento, $serie, $anio)
    );

    db_ejecutar(
        $conexionTenant,
        "UPDATE series_numeracion
         SET ultimo_numero = ultimo_numero + 1
         WHERE tipo_documento = ? AND serie = ? AND anio = ?",
        'ssi',
        array($tipoDocumento, $serie, $anio)
    );

    $filas = db_consultar(
        $conexionTenant,
        "SELECT ultimo_numero FROM series_numeracion
         WHERE tipo_documento = ? AND serie = ? AND anio = ?",
        'ssi',
        array($tipoDocumento, $serie, $anio)
    );

    mysqli_query($conexionTenant, 'COMMIT');

    $numero = $filas[0]['ultimo_numero'];

    return array(
        'numero' => str_pad($numero, 6, '0', STR_PAD_LEFT),
        'serie'  => $serie,
        'anio'   => $anio,
    );
}

/**
 * Calcula subtotal, total_iva y total a partir de un array de lineas.
 * Cada linea: ['cantidad', 'precio_unitario', 'descuento_porcentaje', 'porcentaje_iva']
 */
function calcular_totales_documento($lineas) {
    $subtotal = 0.0;
    $totalIva = 0.0;

    foreach ($lineas as $linea) {
        $importeBruto = $linea['cantidad'] * $linea['precio_unitario'];
        $descuento = $importeBruto * ($linea['descuento_porcentaje'] / 100);
        $importeNeto = $importeBruto - $descuento;
        $iva = $importeNeto * ($linea['porcentaje_iva'] / 100);

        $subtotal += $importeNeto;
        $totalIva += $iva;
    }

    return array(
        'subtotal'  => round($subtotal, 2),
        'total_iva' => round($totalIva, 2),
        'total'     => round($subtotal + $totalIva, 2),
    );
}

/**
 * URL publica de un archivo subido del tenant.
 */
function sf_url_upload_tenant($identificadorTenant, $nombreArchivo) {
    $identificador = preg_replace('/[^a-zA-Z0-9_-]/', '', (string) $identificadorTenant);
    $archivo = rawurlencode((string) $nombreArchivo);
    return rtrim(SF_APP_URL, '/') . '/api/uploads/' . $identificador . '/' . $archivo;
}

/**
 * Enriquece la fila de empresa_configuracion con URL del logo subido.
 */
function sf_enriquecer_empresa_logotipo($fila, $identificadorTenant) {
    if (!empty($fila['logotipo_file'])) {
        $fila['logotipo_archivo_url'] = sf_url_upload_tenant(
            $identificadorTenant,
            $fila['logotipo_file']
        );
    } else {
        $fila['logotipo_archivo_url'] = null;
    }
    return $fila;
}

/**
 * Devuelve columnas de una tabla que NO existen en la BD del tenant.
 */
function sf_tenant_columnas_faltantes($conexion, $tabla, $columnas) {
    $faltantes = array();
    foreach ($columnas as $columna) {
        $filas = db_consultar(
            $conexion,
            "SELECT 1 AS ok FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
             LIMIT 1",
            'ss',
            array($tabla, $columna)
        );
        if (count($filas) === 0) {
            $faltantes[] = $columna;
        }
    }
    return $faltantes;
}
