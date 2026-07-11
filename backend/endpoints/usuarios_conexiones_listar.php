<?php
// ============================================================================
// GET /api/usuarios/conexiones/listar?usuario_id=123
// Cabecera: Authorization: Bearer <token>
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'usuarios.ver');

$usuarioId = isset($_GET['usuario_id']) ? (int) $_GET['usuario_id'] : 0;
if ($usuarioId <= 0) {
    responder_error('usuario_id invalido', 400);
}

$conexiones = db_consultar(
    $conexionTenant,
    "SELECT idUserConexion AS id,
            ipNumberUser AS ip,
            dateConexion AS fecha_conexion
     FROM usersConexions
     WHERE userId = ?
     ORDER BY dateConexion DESC",
    'i',
    array($usuarioId)
);

responder_json($conexiones);
