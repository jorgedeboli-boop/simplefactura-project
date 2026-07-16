<?php
// ============================================================================
// GET /api/facturas/listar?busqueda=texto
// Cabecera: Authorization: Bearer <token>
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'facturas.ver');

$busqueda = isset($_GET['busqueda']) ? limpiar_texto($_GET['busqueda']) : '';

if ($busqueda !== '') {
    $like = '%' . $busqueda . '%';
    $facturas = db_consultar(
        $conexionTenant,
        "SELECT f.*, c.nombre_razon_social AS cliente_nombre
         FROM facturas f
         LEFT JOIN clientes c ON c.id = f.cliente_id
         WHERE f.numero_factura LIKE ? OR c.nombre_razon_social LIKE ?
         ORDER BY f.fecha_emision DESC, f.id DESC",
        'ss',
        array($like, $like)
    );
} else {
    $facturas = db_consultar(
        $conexionTenant,
        "SELECT f.*, c.nombre_razon_social AS cliente_nombre
         FROM facturas f
         LEFT JOIN clientes c ON c.id = f.cliente_id
         ORDER BY f.fecha_emision DESC, f.id DESC"
    );
}

responder_json($facturas);
