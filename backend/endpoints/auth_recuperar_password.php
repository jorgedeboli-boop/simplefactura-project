<?php
// ============================================================================
// POST /api/auth/recuperar-password
// Body: { "email": "usuario@..." }
// Siempre responde igual por seguridad (no revela si el email existe).
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    responder_error('Metodo no permitido', 405);
}

require_once __DIR__ . '/../lib/correo.php';

global $groupIdusersConexions_recupero_pass_ok;
global $groupIdusersConexions_recupero_pass_bad;
global $groupIdusersConexions_recupero_pass_user_block;
global $groupIdusersConexions_recupero_pass_user_inexist;

$entrada = leer_json_entrada();
validar_campos_requeridos($entrada, array('email'));

$email = limpiar_texto($entrada['email']);
$ubicacion = conexion_leer_ubicacion($entrada);

if (!validar_email($email)) {
    responder_error('El email no tiene un formato valido', 400);
}

$mensajeExito = array(
    'mensaje' => 'Si el email esta registrado, recibiras instrucciones para restablecer tu contraseña.',
);

$conexionControl = db_conectar_control();

$tenants = db_consultar(
    $conexionControl,
    "SELECT * FROM tenants WHERE estado IN ('prueba', 'activo')"
);

$tenant = null;
$usuario = null;

foreach ($tenants as $candidato) {
    $conexionCandidata = db_conectar_tenant($candidato);

    $usuarios = db_consultar(
        $conexionCandidata,
        "SELECT id, email, estado FROM usuarios WHERE email = ? LIMIT 1",
        's',
        array($email)
    );

    if (count($usuarios) === 0) {
        continue;
    }

    if ($tenant !== null) {
        // Email duplicado en varios tenants: no enviamos por seguridad.
        responder_json($mensajeExito);
    }

    $tenant = $candidato;
    $usuario = $usuarios[0];
}

if ($tenant === null || $usuario === null) {
    responder_json($mensajeExito);
}

$conexionTenant = db_conectar_tenant($tenant);
$baseLog = array(
    'companyId' => (int) $tenant['id'],
    'locationLong' => $ubicacion['locationLong'],
    'locationLat' => $ubicacion['locationLat'],
    'sucursalId' => $ubicacion['sucursalId'],
    'stateConnection' => 'false',
);

if ($usuario['estado'] !== 'activo') {
    conexion_registrar_log($conexionTenant, array_merge($baseLog, array(
        'userId' => (int) $usuario['id'],
        'groupId' => $groupIdusersConexions_recupero_pass_user_block,
        'logTxt' => 'Recuperacion de contraseña: usuario bloqueado',
    )));
    responder_json($mensajeExito);
}

// Invalidar tokens anteriores pendientes de este usuario.
db_ejecutar(
    $conexionControl,
    "UPDATE tokens_recuperacion_password
     SET usado = 'true'
     WHERE tenant_id = ? AND usuario_id = ? AND usado = 'false'",
    'ii',
    array($tenant['id'], $usuario['id'])
);

$token = auth_generar_token();
$expiracion = date('Y-m-d H:i:s', time() + (SF_RECUPERACION_HORAS_EXPIRACION * 3600));

db_ejecutar(
    $conexionControl,
    "INSERT INTO tokens_recuperacion_password
        (token, tenant_id, usuario_id, email, fecha_expiracion)
     VALUES (?, ?, ?, ?, ?)",
    'siiss',
    array(
        $token,
        $tenant['id'],
        $usuario['id'],
        $email,
        $expiracion,
    )
);

$enlace = rtrim(SF_APP_URL, '/') . '/?recuperar=' . urlencode($token);
$asunto = 'Restablecer contraseña - Simple Factura';
$cuerpo = correo_cuerpo_recuperacion_password($enlace);

correo_enviar($email, $asunto, $cuerpo);

conexion_registrar_log($conexionTenant, array_merge($baseLog, array(
    'userId' => (int) $usuario['id'],
    'groupId' => $groupIdusersConexions_recupero_pass_ok,
    'logTxt' => 'Recuperacion de contraseña: instrucciones enviadas',
)));

responder_json($mensajeExito);
