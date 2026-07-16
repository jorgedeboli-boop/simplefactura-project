<?php
// ============================================================================
// Simple Factura - Helpers para documentos (presupuestos, facturas)
// ============================================================================

/**
 * Obtiene el porcentaje de IVA de un tipo de IVA.
 */
function documento_obtener_iva_porcentaje($conexionTenant, $ivaTipoId) {
    $filas = db_consultar(
        $conexionTenant,
        "SELECT porcentaje FROM iva_tipos WHERE id = ? LIMIT 1",
        'i',
        array($ivaTipoId)
    );

    if (count($filas) === 0) {
        responder_error('Tipo de IVA no encontrado', 400);
    }

    return (float) $filas[0]['porcentaje'];
}

/**
 * Valida y prepara lineas de entrada para calculo e insercion.
 * Cada linea debe incluir: descripcion, cantidad, precio_unitario, iva_tipo_id.
 * Opcional: descuento_porcentaje.
 *
 * @return array lineas con porcentaje_iva, importe_linea y orden
 */
function documento_preparar_lineas($conexionTenant, $lineasEntrada) {
    if (!is_array($lineasEntrada) || count($lineasEntrada) === 0) {
        responder_error('Debe incluir al menos una linea', 400);
    }

    $preparadas = array();
    $orden = 0;

    foreach ($lineasEntrada as $linea) {
        validar_campos_requeridos($linea, array('descripcion', 'cantidad', 'precio_unitario', 'iva_tipo_id'));

        $cantidad = a_decimal($linea['cantidad'], 1.0);
        $precioUnitario = a_decimal($linea['precio_unitario']);
        $descuentoPorcentaje = a_decimal(
            isset($linea['descuento_porcentaje']) ? $linea['descuento_porcentaje'] : 0
        );
        $ivaTipoId = (int) $linea['iva_tipo_id'];

        if ($cantidad <= 0) {
            responder_error('La cantidad debe ser mayor que cero', 400);
        }

        $porcentajeIva = documento_obtener_iva_porcentaje($conexionTenant, $ivaTipoId);

        $importeBruto = $cantidad * $precioUnitario;
        $descuento = $importeBruto * ($descuentoPorcentaje / 100);
        $importeNeto = $importeBruto - $descuento;
        $iva = $importeNeto * ($porcentajeIva / 100);
        $importeLinea = round($importeNeto + $iva, 2);

        $preparadas[] = array(
            'descripcion'           => limpiar_texto($linea['descripcion']),
            'cantidad'              => $cantidad,
            'precio_unitario'       => $precioUnitario,
            'descuento_porcentaje'  => $descuentoPorcentaje,
            'iva_tipo_id'           => $ivaTipoId,
            'porcentaje_iva'        => $porcentajeIva,
            'importe_linea'         => $importeLinea,
            'orden'                 => $orden,
        );
        $orden++;
    }

    return $preparadas;
}

/**
 * Inserta lineas preparadas en presupuestos_lineas o facturas_lineas.
 */
function documento_insertar_lineas($conexionTenant, $tabla, $columnaDocumentoId, $documentoId, $lineasPreparadas) {
    $tablasPermitidas = array(
        'presupuestos_lineas' => 'presupuesto_id',
        'facturas_lineas'     => 'factura_id',
    );

    if (!isset($tablasPermitidas[$tabla]) || $tablasPermitidas[$tabla] !== $columnaDocumentoId) {
        responder_error('Tabla de lineas no valida', 500);
    }

    foreach ($lineasPreparadas as $linea) {
        db_ejecutar(
            $conexionTenant,
            "INSERT INTO {$tabla}
                ({$columnaDocumentoId}, descripcion, cantidad, precio_unitario,
                 descuento_porcentaje, iva_tipo_id, importe_linea, orden)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            'isdddidi',
            array(
                $documentoId,
                $linea['descripcion'],
                $linea['cantidad'],
                $linea['precio_unitario'],
                $linea['descuento_porcentaje'],
                $linea['iva_tipo_id'],
                $linea['importe_linea'],
                $linea['orden'],
            )
        );
    }
}

/**
 * Elimina todas las lineas de un documento.
 */
function documento_eliminar_lineas($conexionTenant, $tabla, $columnaDocumentoId, $documentoId) {
    $tablasPermitidas = array(
        'presupuestos_lineas' => 'presupuesto_id',
        'facturas_lineas'     => 'factura_id',
    );

    if (!isset($tablasPermitidas[$tabla]) || $tablasPermitidas[$tabla] !== $columnaDocumentoId) {
        responder_error('Tabla de lineas no valida', 500);
    }

    db_ejecutar(
        $conexionTenant,
        "DELETE FROM {$tabla} WHERE {$columnaDocumentoId} = ?",
        'i',
        array($documentoId)
    );
}

/**
 * Mapea tipo_factura al tipo de numeracion de series_numeracion.
 */
function documento_tipo_numeracion_factura($tipoFactura) {
    $mapa = array(
        'normal'        => 'factura',
        'simplificada'  => 'factura_simplificada',
        'rectificativa' => 'factura_rectificativa',
    );

    if (!isset($mapa[$tipoFactura])) {
        responder_error('Tipo de factura no valido', 400);
    }

    return $mapa[$tipoFactura];
}

/**
 * Formatea el numero compuesto anio-serie-correlativo.
 */
function documento_formatear_numero($numeracion) {
    return $numeracion['anio'] . '-' . $numeracion['serie'] . '-' . $numeracion['numero'];
}

/**
 * Obtiene un presupuesto completo con lineas e info del cliente.
 */
function documento_obtener_presupuesto_completo($conexionTenant, $id) {
    $presupuestos = db_consultar(
        $conexionTenant,
        "SELECT p.*, c.nombre_razon_social AS cliente_nombre
         FROM presupuestos p
         INNER JOIN clientes c ON c.id = p.cliente_id
         WHERE p.id = ?
         LIMIT 1",
        'i',
        array($id)
    );

    if (count($presupuestos) === 0) {
        return null;
    }

    $lineas = db_consultar(
        $conexionTenant,
        "SELECT pl.*, it.nombre AS iva_tipo_nombre, it.porcentaje AS iva_porcentaje
         FROM presupuestos_lineas pl
         INNER JOIN iva_tipos it ON it.id = pl.iva_tipo_id
         WHERE pl.presupuesto_id = ?
         ORDER BY pl.orden ASC",
        'i',
        array($id)
    );

    $presupuestos[0]['lineas'] = $lineas;
    return $presupuestos[0];
}

/**
 * Obtiene una factura completa con lineas e info del cliente.
 */
function documento_obtener_factura_completa($conexionTenant, $id) {
    $facturas = db_consultar(
        $conexionTenant,
        "SELECT f.*, c.nombre_razon_social AS cliente_nombre
         FROM facturas f
         LEFT JOIN clientes c ON c.id = f.cliente_id
         WHERE f.id = ?
         LIMIT 1",
        'i',
        array($id)
    );

    if (count($facturas) === 0) {
        return null;
    }

    $lineas = db_consultar(
        $conexionTenant,
        "SELECT fl.*, it.nombre AS iva_tipo_nombre, it.porcentaje AS iva_porcentaje
         FROM facturas_lineas fl
         INNER JOIN iva_tipos it ON it.id = fl.iva_tipo_id
         WHERE fl.factura_id = ?
         ORDER BY fl.orden ASC",
        'i',
        array($id)
    );

    $facturas[0]['lineas'] = $lineas;
    return $facturas[0];
}
