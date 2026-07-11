<?php
// ============================================================================
// PUT /api/usuarios/actualizar
// Cabecera: Authorization: Bearer <token>
// Body: { id, nombre, apellidos, email, telefono, role_id, estado, password? }
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'PUT' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'usuarios.editar');

$entrada = leer_json_entrada();
validar_campos_requeridos($entrada, array('id', 'nombre', 'email', 'role_id', 'estado'));

$id = (int) $entrada['id'];
$email = limpiar_texto($entrada['email']);

if (!validar_email($email)) {
    responder_error('El email no tiene un formato valido', 400);
}

if (!in_array($entrada['estado'], array('activo', 'inactivo'), true)) {
    responder_error('Estado no valido', 400);
}

$existentes = db_consultar(
    $conexionTenant,
    "SELECT id FROM usuarios WHERE email = ? AND id != ? LIMIT 1",
    'si',
    array($email, $id)
);
if (count($existentes) > 0) {
    responder_error('Ya existe un usuario con ese email', 409);
}

$sets = array(
    'nombre = ?',
    'apellidos = ?',
    'email = ?',
    'telefono = ?',
    'role_id = ?',
    'estado = ?',
);
$tipos = 'ssssis';
$valores = array(
    limpiar_texto($entrada['nombre']),
    isset($entrada['apellidos']) ? limpiar_texto($entrada['apellidos']) : null,
    $email,
    isset($entrada['telefono']) ? limpiar_texto($entrada['telefono']) : null,
    (int) $entrada['role_id'],
    $entrada['estado'],
);

if (!empty($entrada['password'])) {
    if (strlen($entrada['password']) < 8) {
        responder_error('La contraseña debe tener al menos 8 caracteres', 400);
    }
    $sets[] = 'password_hash = ?';
    $tipos .= 's';
    $valores[] = password_hash($entrada['password'], PASSWORD_BCRYPT);
}

$valores[] = $id;
$tipos .= 'i';

$sql = 'UPDATE usuarios SET ' . implode(', ', $sets) . ' WHERE id = ?';
$resultado = db_ejecutar($conexionTenant, $sql, $tipos, $valores);

if ($resultado['filas_afectadas'] === 0) {
    responder_error('Usuario no encontrado', 404);
}

$usuarios = db_consultar(
    $conexionTenant,
    "SELECT u.id, u.nombre, u.apellidos, u.email, u.telefono, u.estado,
            u.ultimo_acceso, u.fecha_creacion, r.id AS role_id, r.nombre AS role_nombre,
            (SELECT MAX(c.dateConexion)
             FROM usersConexions c
             WHERE c.userId = u.id) AS ultima_conexion
     FROM usuarios u
     INNER JOIN roles r ON r.id = u.role_id
     WHERE u.id = ?
     LIMIT 1",
    'i',
    array($id)
);

if (count($usuarios) === 0) {
    responder_error('Usuario no encontrado', 404);
}

responder_json($usuarios[0]);
