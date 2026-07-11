<?php
// ============================================================================
// POST /api/usuarios/crear
// Cabecera: Authorization: Bearer <token>
// Body: { nombre, apellidos, email, password, telefono, role_id }
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'usuarios.crear');

$entrada = leer_json_entrada();
validar_campos_requeridos($entrada, array('nombre', 'email', 'password', 'role_id'));

$email = limpiar_texto($entrada['email']);
if (!validar_email($email)) {
    responder_error('El email no tiene un formato valido', 400);
}

if (strlen($entrada['password']) < 8) {
    responder_error('La contraseña debe tener al menos 8 caracteres', 400);
}

$existentes = db_consultar(
    $conexionTenant,
    "SELECT id FROM usuarios WHERE email = ? LIMIT 1",
    's',
    array($email)
);
if (count($existentes) > 0) {
    responder_error('Ya existe un usuario con ese email', 409);
}

$hash = password_hash($entrada['password'], PASSWORD_BCRYPT);

$resultado = db_ejecutar(
    $conexionTenant,
    "INSERT INTO usuarios (nombre, apellidos, email, password_hash, telefono, role_id, estado)
     VALUES (?, ?, ?, ?, ?, ?, 'activo')",
    'sssssi',
    array(
        limpiar_texto($entrada['nombre']),
        isset($entrada['apellidos']) ? limpiar_texto($entrada['apellidos']) : null,
        $email,
        $hash,
        isset($entrada['telefono']) ? limpiar_texto($entrada['telefono']) : null,
        (int) $entrada['role_id'],
    )
);

responder_json(array(
    'id'      => $resultado['id_insertado'],
    'mensaje' => 'Usuario creado correctamente',
), 201);
