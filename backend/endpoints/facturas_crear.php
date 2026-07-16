<?php
// ============================================================================
// POST /api/facturas/crear
// Cabecera: Authorization: Bearer <token>
// Body: { tipo_factura?, cliente_id?, fecha_emision, fecha_vencimiento?, estado?,
//         forma_pago?, moneda_codigo, notas?, lineas[] }
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'facturas.crear');

$entrada = leer_json_entrada();
validar_campos_requeridos($entrada, array('fecha_emision', 'moneda_codigo', 'lineas'));

$tiposValidos = array('normal', 'simplificada', 'rectificativa');
$tipoFactura = isset($entrada['tipo_factura']) && in_array($entrada['tipo_factura'], $tiposValidos, true)
    ? $entrada['tipo_factura']
    : 'normal';

$estadosValidos = array('borrador', 'emitida', 'pagada', 'vencida', 'anulada');
$estado = isset($entrada['estado']) && in_array($entrada['estado'], $estadosValidos, true)
    ? $entrada['estado']
    : 'emitida';

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

$tipoNumeracion = documento_tipo_numeracion_factura($tipoFactura);
$numeracion = generar_numero_documento($conexionTenant, $tipoNumeracion);
$serie = $numeracion['serie'];
$numeroFactura = $numeracion['numero'];

mysqli_query($conexionTenant, 'START TRANSACTION');

$resultado = db_ejecutar(
    $conexionTenant,
    "INSERT INTO facturas
        (tipo_factura, numero_factura, serie, cliente_id, fecha_emision, fecha_vencimiento,
         estado, forma_pago, subtotal, total_iva, total, moneda_codigo, notas, usuario_id)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    'sssissssdddssi',
    array(
        $tipoFactura,
        $numeroFactura,
        $serie,
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
        $sesion['usuario_id'],
    )
);

$facturaId = $resultado['id_insertado'];
documento_insertar_lineas($conexionTenant, 'facturas_lineas', 'factura_id', $facturaId, $lineasPreparadas);

mysqli_query($conexionTenant, 'COMMIT');

$factura = documento_obtener_factura_completa($conexionTenant, $facturaId);
responder_json($factura, 201);
