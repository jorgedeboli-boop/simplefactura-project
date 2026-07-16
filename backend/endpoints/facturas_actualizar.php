<?php
// ============================================================================
// PUT/POST /api/facturas/actualizar
// Cabecera: Authorization: Bearer <token>
// Body: { id, tipo_factura?, cliente_id?, fecha_emision, fecha_vencimiento?, estado,
//         forma_pago?, moneda_codigo, notas?, lineas[] }
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'PUT' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'facturas.editar');

$entrada = leer_json_entrada();
validar_campos_requeridos($entrada, array('id', 'fecha_emision', 'moneda_codigo', 'lineas'));

$id = (int) $entrada['id'];

$existentes = db_consultar(
    $conexionTenant,
    "SELECT id, tipo_factura FROM facturas WHERE id = ? LIMIT 1",
    'i',
    array($id)
);
if (count($existentes) === 0) {
    responder_error('Factura no encontrada', 404);
}

$tiposValidos = array('normal', 'simplificada', 'rectificativa');
$tipoFactura = isset($entrada['tipo_factura']) && in_array($entrada['tipo_factura'], $tiposValidos, true)
    ? $entrada['tipo_factura']
    : $existentes[0]['tipo_factura'];

$estadosValidos = array('borrador', 'emitida', 'pagada', 'vencida', 'anulada');
if (isset($entrada['estado']) && !in_array($entrada['estado'], $estadosValidos, true)) {
    responder_error('Estado no valido', 400);
}
$estado = isset($entrada['estado']) ? $entrada['estado'] : 'emitida';

$clienteId = null;
if (isset($entrada['cliente_id']) && $entrada['cliente_id'] !== '' && $entrada['cliente_id'] !== null) {
    $clienteId = (int) $entrada['cliente_id'];
    $clientes = db_consultar(
        $conexionTenant,
        "SELECT id FROM clientes WHERE id = ? LIMIT 1",
        'i',
        array($clienteId)
    );
    if (count($clientes) === 0) {
        responder_error('Cliente no encontrado', 404);
    }
}

$lineasPreparadas = documento_preparar_lineas($conexionTenant, $entrada['lineas']);
$totales = calcular_totales_documento($lineasPreparadas);

mysqli_query($conexionTenant, 'START TRANSACTION');

db_ejecutar(
    $conexionTenant,
    "UPDATE facturas SET
        tipo_factura = ?,
        cliente_id = ?,
        fecha_emision = ?,
        fecha_vencimiento = ?,
        estado = ?,
        forma_pago = ?,
        subtotal = ?,
        total_iva = ?,
        total = ?,
        moneda_codigo = ?,
        notas = ?
     WHERE id = ?",
    'sissssdddssi',
    array(
        $tipoFactura,
        $clienteId,
        $entrada['fecha_emision'],
        isset($entrada['fecha_vencimiento']) ? $entrada['fecha_vencimiento'] : null,
        $estado,
        isset($entrada['forma_pago']) ? limpiar_texto($entrada['forma_pago']) : null,
        $totales['subtotal'],
        $totales['total_iva'],
        $totales['total'],
        limpiar_texto($entrada['moneda_codigo']),
        isset($entrada['notas']) ? limpiar_texto($entrada['notas']) : null,
        $id,
    )
);

documento_eliminar_lineas($conexionTenant, 'facturas_lineas', 'factura_id', $id);
documento_insertar_lineas($conexionTenant, 'facturas_lineas', 'factura_id', $id, $lineasPreparadas);

mysqli_query($conexionTenant, 'COMMIT');

$factura = documento_obtener_factura_completa($conexionTenant, $id);
responder_json($factura);
