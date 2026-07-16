<?php
// ============================================================================
// POST /api/presupuestos/crear
// Cabecera: Authorization: Bearer <token>
// Body: { cliente_id, fecha_emision, fecha_validez?, estado?, moneda_codigo,
//         notas?, lineas[] }
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'presupuestos.crear');

$entrada = leer_json_entrada();
validar_campos_requeridos($entrada, array('cliente_id', 'fecha_emision', 'moneda_codigo', 'lineas'));

$clienteId = (int) $entrada['cliente_id'];
$estadosValidos = array('borrador', 'enviado', 'aceptado', 'rechazado', 'facturado');
$estado = isset($entrada['estado']) && in_array($entrada['estado'], $estadosValidos, true)
    ? $entrada['estado']
    : 'borrador';

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

$numeracion = generar_numero_documento($conexionTenant, 'presupuesto');
$numeroPresupuesto = documento_formatear_numero($numeracion);

mysqli_query($conexionTenant, 'START TRANSACTION');

$resultado = db_ejecutar(
    $conexionTenant,
    "INSERT INTO presupuestos
        (numero_presupuesto, cliente_id, fecha_emision, fecha_validez, estado,
         subtotal, total_iva, total, moneda_codigo, notas, usuario_id)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    'sisssdddssi',
    array(
        $numeroPresupuesto,
        $clienteId,
        $entrada['fecha_emision'],
        isset($entrada['fecha_validez']) ? $entrada['fecha_validez'] : null,
        $estado,
        $totales['subtotal'],
        $totales['total_iva'],
        $totales['total'],
        limpiar_texto($entrada['moneda_codigo']),
        isset($entrada['notas']) ? limpiar_texto($entrada['notas']) : null,
        $sesion['usuario_id'],
    )
);

$presupuestoId = $resultado['id_insertado'];
documento_insertar_lineas($conexionTenant, 'presupuestos_lineas', 'presupuesto_id', $presupuestoId, $lineasPreparadas);

mysqli_query($conexionTenant, 'COMMIT');

$presupuesto = documento_obtener_presupuesto_completo($conexionTenant, $presupuestoId);
responder_json($presupuesto, 201);
