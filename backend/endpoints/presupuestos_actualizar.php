<?php
// ============================================================================
// PUT/POST /api/presupuestos/actualizar
// Cabecera: Authorization: Bearer <token>
// Body: { id, cliente_id, fecha_emision, fecha_validez?, estado, moneda_codigo,
//         notas?, lineas[] }
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'PUT' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'presupuestos.editar');

$entrada = leer_json_entrada();
validar_campos_requeridos($entrada, array('id', 'cliente_id', 'fecha_emision', 'moneda_codigo', 'lineas'));

$id = (int) $entrada['id'];
$clienteId = (int) $entrada['cliente_id'];

$estadosValidos = array('borrador', 'enviado', 'aceptado', 'rechazado', 'facturado');
if (isset($entrada['estado']) && !in_array($entrada['estado'], $estadosValidos, true)) {
    responder_error('Estado no valido', 400);
}
$estado = isset($entrada['estado']) ? $entrada['estado'] : 'borrador';

$existentes = db_consultar(
    $conexionTenant,
    "SELECT id FROM presupuestos WHERE id = ? LIMIT 1",
    'i',
    array($id)
);
if (count($existentes) === 0) {
    responder_error('Presupuesto no encontrado', 404);
}

$clientes = db_consultar(
    $conexionTenant,
    "SELECT id FROM clientes WHERE id = ? LIMIT 1",
    'i',
    array($clienteId)
);
if (count($clientes) === 0) {
    responder_error('Cliente no encontrado', 404);
}

$lineasPreparadas = documento_preparar_lineas($conexionTenant, $entrada['lineas']);
$totales = calcular_totales_documento($lineasPreparadas);

mysqli_query($conexionTenant, 'START TRANSACTION');

db_ejecutar(
    $conexionTenant,
    "UPDATE presupuestos SET
        cliente_id = ?,
        fecha_emision = ?,
        fecha_validez = ?,
        estado = ?,
        subtotal = ?,
        total_iva = ?,
        total = ?,
        moneda_codigo = ?,
        notas = ?
     WHERE id = ?",
    'isssdddssi',
    array(
        $clienteId,
        $entrada['fecha_emision'],
        isset($entrada['fecha_validez']) ? $entrada['fecha_validez'] : null,
        $estado,
        $totales['subtotal'],
        $totales['total_iva'],
        $totales['total'],
        limpiar_texto($entrada['moneda_codigo']),
        isset($entrada['notas']) ? limpiar_texto($entrada['notas']) : null,
        $id,
    )
);

documento_eliminar_lineas($conexionTenant, 'presupuestos_lineas', 'presupuesto_id', $id);
documento_insertar_lineas($conexionTenant, 'presupuestos_lineas', 'presupuesto_id', $id, $lineasPreparadas);

mysqli_query($conexionTenant, 'COMMIT');

$presupuesto = documento_obtener_presupuesto_completo($conexionTenant, $id);
responder_json($presupuesto);
