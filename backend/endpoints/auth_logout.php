<?php
// ============================================================================
// POST /api/auth/logout
// Cabecera: Authorization: Bearer <token>
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    responder_error('Metodo no permitido', 405);
}

global $groupIdusersConexions_Cierre_de_sesion;

$token = auth_leer_token_cabecera();
if (!$token) {
    responder_error('Falta el token de autenticacion', 401);
}

$conexionControl = db_conectar_control();

$filas = db_consultar(
    $conexionControl,
    "SELECT tg.usuario_id, tg.token, t.*
     FROM tokens_globales tg
     INNER JOIN tenants t ON t.id = tg.tenant_id
     WHERE tg.token = ?
     LIMIT 1",
    's',
    array($token)
);

if (count($filas) > 0) {
    $fila = $filas[0];
    $conexionTenant = db_conectar_tenant($fila);

    conexion_registrar_log($conexionTenant, array(
        'userId' => (int) $fila['usuario_id'],
        'groupId' => $groupIdusersConexions_Cierre_de_sesion,
        'logTxt' => 'Cierre de sesion',
        'companyId' => (int) $fila['id'],
        'tokenSesion' => $token,
        'stateConnection' => 'false',
    ));
}

db_ejecutar(
    $conexionControl,
    "DELETE FROM tokens_globales WHERE token = ?",
    's',
    array($token)
);

responder_json(array('mensaje' => 'Sesion cerrada correctamente'));
