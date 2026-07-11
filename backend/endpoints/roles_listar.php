<?php
// ============================================================================
// GET /api/roles/listar
// Cabecera: Authorization: Bearer <token>
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'usuarios.ver');

$roles = db_consultar(
    $conexionTenant,
    "SELECT id, nombre, nivel, descripcion FROM roles ORDER BY nivel ASC"
);

responder_json($roles);
