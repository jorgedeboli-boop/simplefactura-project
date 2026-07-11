<?php
// ============================================================================
// GET /api/usuarios/listar
// Cabecera: Authorization: Bearer <token>
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'usuarios.ver');

$usuarios = db_consultar(
    $conexionTenant,
    "SELECT u.id, u.nombre, u.apellidos, u.email, u.telefono, u.estado,
            u.ultimo_acceso, u.fecha_creacion, r.id AS role_id, r.nombre AS role_nombre,
            (SELECT MAX(c.dateConexion)
             FROM usersConexions c
             WHERE c.userId = u.id) AS ultima_conexion
     FROM usuarios u
     INNER JOIN roles r ON r.id = u.role_id
     ORDER BY u.nombre ASC"
);

responder_json($usuarios);
