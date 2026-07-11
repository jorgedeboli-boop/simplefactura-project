<?php
// ============================================================================
// GET /api/clientes/listar?estado=activo&busqueda=texto
// Cabecera: Authorization: Bearer <token>
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'clientes.ver');

$busqueda = isset($_GET['busqueda']) ? limpiar_texto($_GET['busqueda']) : '';

if ($busqueda !== '') {
    $like = '%' . $busqueda . '%';
    $clientes = db_consultar(
        $conexionTenant,
        "SELECT c.*, p.nombre AS pais_nombre
         FROM clientes c
         LEFT JOIN paises p ON p.id = c.pais_id
         WHERE c.nombre_razon_social LIKE ? OR c.identificacion_fiscal LIKE ? OR c.email LIKE ?
         ORDER BY c.nombre_razon_social ASC",
        'sss',
        array($like, $like, $like)
    );
} else {
    $clientes = db_consultar(
        $conexionTenant,
        "SELECT c.*, p.nombre AS pais_nombre
         FROM clientes c
         LEFT JOIN paises p ON p.id = c.pais_id
         ORDER BY c.nombre_razon_social ASC"
    );
}

responder_json($clientes);
