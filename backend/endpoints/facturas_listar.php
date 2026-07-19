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
$clienteId = isset($_GET['cliente_id']) ? (int) $_GET['cliente_id'] : 0;

$condiciones = array();
$tipos = '';
$params = array();

if ($clienteId > 0) {
    $condiciones[] = 'f.cliente_id = ?';
    $tipos .= 'i';
    $params[] = $clienteId;
}

if ($busqueda !== '') {
    $like = '%' . $busqueda . '%';
    $condiciones[] = '(f.numero_factura LIKE ? OR c.nombre_razon_social LIKE ?)';
    $tipos .= 'ss';
    $params[] = $like;
    $params[] = $like;
}

$sql = "SELECT f.*, c.nombre_razon_social AS cliente_nombre
        FROM facturas f
        LEFT JOIN clientes c ON c.id = f.cliente_id";

if (count($condiciones) > 0) {
    $sql .= ' WHERE ' . implode(' AND ', $condiciones);
}

$sql .= ' ORDER BY f.fecha_emision DESC, f.id DESC';

if ($tipos !== '') {
    $facturas = db_consultar($conexionTenant, $sql, $tipos, $params);
} else {
    $facturas = db_consultar($conexionTenant, $sql);
}

responder_json($facturas);
