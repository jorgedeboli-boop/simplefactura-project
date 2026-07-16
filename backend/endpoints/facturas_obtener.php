<?php
// ============================================================================
// GET /api/facturas/obtener?id=123
// Cabecera: Authorization: Bearer <token>
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'facturas.ver');

if (!isset($_GET['id']) || $_GET['id'] === '') {
    responder_error('ID de factura requerido', 400);
}

$id = (int) $_GET['id'];
$factura = documento_obtener_factura_completa($conexionTenant, $id);

if ($factura === null) {
    responder_error('Factura no encontrada', 404);
}

responder_json($factura);
