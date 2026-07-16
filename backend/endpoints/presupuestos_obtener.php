<?php
// ============================================================================
// GET /api/presupuestos/obtener?id=123
// Cabecera: Authorization: Bearer <token>
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'presupuestos.ver');

if (!isset($_GET['id']) || $_GET['id'] === '') {
    responder_error('ID de presupuesto requerido', 400);
}

$id = (int) $_GET['id'];
$presupuesto = documento_obtener_presupuesto_completo($conexionTenant, $id);

if ($presupuesto === null) {
    responder_error('Presupuesto no encontrado', 404);
}

responder_json($presupuesto);
