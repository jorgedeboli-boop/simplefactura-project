<?php
// ============================================================================
// GET /api/presupuestos/listar?busqueda=texto
// Cabecera: Authorization: Bearer <token>
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'presupuestos.ver');

$busqueda = isset($_GET['busqueda']) ? limpiar_texto($_GET['busqueda']) : '';

if ($busqueda !== '') {
    $like = '%' . $busqueda . '%';
    $presupuestos = db_consultar(
        $conexionTenant,
        "SELECT p.*, c.nombre_razon_social AS cliente_nombre
         FROM presupuestos p
         INNER JOIN clientes c ON c.id = p.cliente_id
         WHERE p.numero_presupuesto LIKE ? OR c.nombre_razon_social LIKE ?
         ORDER BY p.fecha_emision DESC, p.id DESC",
        'ss',
        array($like, $like)
    );
} else {
    $presupuestos = db_consultar(
        $conexionTenant,
        "SELECT p.*, c.nombre_razon_social AS cliente_nombre
         FROM presupuestos p
         INNER JOIN clientes c ON c.id = p.cliente_id
         ORDER BY p.fecha_emision DESC, p.id DESC"
    );
}

responder_json($presupuestos);
