<?php
// ============================================================================
// POST /api/auth/login
// Body: { "email": "admin@...", "password": "..." }
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    responder_error('Metodo no permitido', 405);
}

$entrada = leer_json_entrada();
validar_campos_requeridos($entrada, array('email', 'password'));

$email    = limpiar_texto($entrada['email']);
$password = $entrada['password'];
$ubicacion = conexion_leer_ubicacion($entrada);

if (!validar_email($email)) {
    responder_error('El email no tiene un formato valido', 400);
}

global $groupIdusersConexions_Empresa_sin_acceso;
global $groupIdusersConexions_Usuario_no_jerarquia;
global $groupIdusersConexions_Usuario_bloqueado;
global $groupIdusersConexions_login_correcto;
global $groupIdusersConexions_Login_Fallido;

$conexionControl = db_conectar_control();

// Empresa suspendida o dada de baja
$resultadoSuspendido = conexion_buscar_usuario_por_email(
    $conexionControl,
    $email,
    array('suspendido', 'baja')
);

if ($resultadoSuspendido !== null && !isset($resultadoSuspendido['duplicado'])) {
    conexion_registrar_log($resultadoSuspendido['conexionTenant'], array(
        'userId' => (int) $resultadoSuspendido['usuario']['id'],
        'groupId' => $groupIdusersConexions_Empresa_sin_acceso,
        'logTxt' => 'Intento de acceso con empresa sin acceso activo',
        'companyId' => (int) $resultadoSuspendido['tenant']['id'],
        'stateConnection' => 'false',
        'locationLong' => $ubicacion['locationLong'],
        'locationLat' => $ubicacion['locationLat'],
        'sucursalId' => $ubicacion['sucursalId'],
    ));
    responder_error('La cuenta de esta empresa no esta activa', 403);
}

// Buscar usuario en tenants activos
$resultado = conexion_buscar_usuario_por_email(
    $conexionControl,
    $email,
    array('prueba', 'activo')
);

if ($resultado === null) {
    responder_error('Credenciales incorrectas', 401);
}

if (isset($resultado['duplicado'])) {
    responder_error('Este email esta asociado a varias cuentas. Contacta con soporte.', 409);
}

$tenant = $resultado['tenant'];
$usuario = $resultado['usuario'];
$conexionTenant = $resultado['conexionTenant'];
$companyId = (int) $tenant['id'];
$userId = (int) $usuario['id'];

$baseLog = array(
    'companyId' => $companyId,
    'locationLong' => $ubicacion['locationLong'],
    'locationLat' => $ubicacion['locationLat'],
    'sucursalId' => $ubicacion['sucursalId'],
);

if ($usuario['estado'] !== 'activo') {
    conexion_registrar_log($conexionTenant, array_merge($baseLog, array(
        'userId' => $userId,
        'groupId' => $groupIdusersConexions_Usuario_bloqueado,
        'logTxt' => 'Usuario bloqueado o inactivo',
        'stateConnection' => 'false',
    )));
    responder_error('Tu usuario esta inactivo. Contacta con el administrador.', 403);
}

$roles = db_consultar(
    $conexionTenant,
    "SELECT id FROM roles WHERE id = ? LIMIT 1",
    'i',
    array($usuario['role_id'])
);

if (count($roles) === 0) {
    conexion_registrar_log($conexionTenant, array_merge($baseLog, array(
        'userId' => $userId,
        'groupId' => $groupIdusersConexions_Usuario_no_jerarquia,
        'logTxt' => 'Usuario sin jerarquia (rol) asignada',
        'stateConnection' => 'false',
    )));
    responder_error('Tu usuario no tiene una jerarquia valida. Contacta con el administrador.', 403);
}

if (!password_verify($password, $usuario['password_hash'])) {
    conexion_registrar_log($conexionTenant, array_merge($baseLog, array(
        'userId' => $userId,
        'groupId' => $groupIdusersConexions_Login_Fallido,
        'logTxt' => 'Login fallido: contraseña incorrecta',
        'stateConnection' => 'false',
    )));
    responder_error('Credenciales incorrectas', 401);
}

// Crear token global y actualizar ultimo acceso
$token = auth_generar_token();
$expiracion = date('Y-m-d H:i:s', time() + (SF_TOKEN_HORAS_EXPIRACION * 3600));

db_ejecutar(
    $conexionControl,
    "INSERT INTO tokens_globales (token, tenant_id, usuario_id, ip, user_agent, fecha_expiracion)
     VALUES (?, ?, ?, ?, ?, ?)",
    'siisss',
    array(
        $token,
        $tenant['id'],
        $usuario['id'],
        isset($_SERVER['REMOTE_ADDR']) ? $_SERVER['REMOTE_ADDR'] : null,
        isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : null,
        $expiracion,
    )
);

db_ejecutar(
    $conexionTenant,
    "UPDATE usuarios SET ultimo_acceso = NOW() WHERE id = ?",
    'i',
    array($usuario['id'])
);

conexion_registrar_log($conexionTenant, array_merge($baseLog, array(
    'userId' => $userId,
    'groupId' => $groupIdusersConexions_login_correcto,
    'logTxt' => 'Login correcto',
    'tokenSesion' => $token,
    'stateConnection' => 'true',
)));

responder_json(array(
    'token'      => $token,
    'expira_en'  => $expiracion,
    'empresa'    => array(
        'identificador'  => $tenant['identificador'],
        'nombre_empresa' => $tenant['nombre_empresa'],
    ),
    'usuario'    => array(
        'id'        => (int) $usuario['id'],
        'nombre'    => $usuario['nombre'],
        'apellidos' => $usuario['apellidos'],
        'email'     => $usuario['email'],
        'role_id'   => (int) $usuario['role_id'],
    ),
));
