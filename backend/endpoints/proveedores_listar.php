<?php
// ============================================================================
// GET /api/proveedores/listar?busqueda=texto
// Cabecera: Authorization: Bearer <token>
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'proveedores.ver');

$busqueda = isset($_GET['busqueda']) ? limpiar_texto($_GET['busqueda']) : '';

if ($busqueda !== '') {
    $like = '%' . $busqueda . '%';
    $proveedores = db_consultar(
        $conexionTenant,
        "SELECT pr.*, p.nombre AS pais_nombre
         FROM proveedores pr
         LEFT JOIN paises p ON p.id = pr.pais_id
         WHERE pr.nombre_razon_social LIKE ? OR pr.identificacion_fiscal LIKE ? OR pr.email LIKE ?
         ORDER BY pr.nombre_razon_social ASC",
        'sss',
        array($like, $like, $like)
    );
} else {
    $proveedores = db_consultar(
        $conexionTenant,
        "SELECT pr.*, p.nombre AS pais_nombre
         FROM proveedores pr
         LEFT JOIN paises p ON p.id = pr.pais_id
         ORDER BY pr.nombre_razon_social ASC"
    );
}

responder_json($proveedores);
