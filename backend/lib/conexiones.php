<?php
// ============================================================================
// Simple Factura - Registro de conexiones / auditoria de sesion (usersConexions)
// ============================================================================

// DEFINO LOS NUMEROS DE ERRORES POR INICIO DE SESION FALLIDO
$groupIdusersConexions_Empresa_sin_acceso = 58;
$groupIdusersConexions_Cierre_de_sesion = 57;
$groupIdusersConexions_Usuario_eliminado = 56;
$groupIdusersConexions_Usuario_no_jerarquia = 88;
$groupIdusersConexions_Desconectado = 55;
$groupIdusersConexions_Usuario_bloqueado = 54;
$groupIdusersConexions_login_correcto = 52;
$groupIdusersConexions_Login_Fallido = 53;
$groupIdusersConexions_recupero_pass_ok = 62;
$groupIdusersConexions_recupero_pass_bad = 63;
$groupIdusersConexions_recupero_pass_user_block = 64;
$groupIdusersConexions_recupero_pass_user_inexist = 65;

/**
 * Inserta un registro en usersConexions del tenant.
 * Falla en silencio si la tabla no existe (compatibilidad con tenants antiguos).
 */
function conexion_registrar_log($conexionTenant, $opciones) {
    $userId = isset($opciones['userId']) ? (int) $opciones['userId'] : 0;
    $groupId = (int) $opciones['groupId'];
    $logTxt = isset($opciones['logTxt']) ? $opciones['logTxt'] : '';
    $companyId = isset($opciones['companyId']) ? (int) $opciones['companyId'] : 0;
    $tokenSesion = isset($opciones['tokenSesion']) ? $opciones['tokenSesion'] : '';
    $stateConnection = isset($opciones['stateConnection']) ? $opciones['stateConnection'] : 'false';
    $sucursalId = isset($opciones['sucursalId']) ? (int) $opciones['sucursalId'] : 0;
    $locationLong = isset($opciones['locationLong']) ? $opciones['locationLong'] : '0';
    $locationLat = isset($opciones['locationLat']) ? $opciones['locationLat'] : '0';

    $ip = isset($_SERVER['REMOTE_ADDR']) ? $_SERVER['REMOTE_ADDR'] : '';
    $userAgent = isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : '';

    if ($stateConnection !== 'true') {
        $stateConnection = 'false';
    }

    $stmt = mysqli_prepare(
        $conexionTenant,
        "INSERT INTO usersConexions (
            userId, locationLong, locationLat, dateConexion, groupId, logTxt,
            sucursalIdUserConexion, companyIdUserConexion, ipNumberUser, userAgent,
            tokensessioncontrol, state_connection
         ) VALUES (?, ?, ?, NOW(), ?, ?, ?, ?, ?, ?, ?, ?)"
    );

    if (!$stmt) {
        return;
    }

    mysqli_stmt_bind_param(
        $stmt,
        'issisississ',
        $userId,
        $locationLong,
        $locationLat,
        $groupId,
        $logTxt,
        $sucursalId,
        $companyId,
        $ip,
        $userAgent,
        $tokenSesion,
        $stateConnection
    );

    mysqli_stmt_execute($stmt);
    mysqli_stmt_close($stmt);
}

/**
 * Lee coordenadas opcionales del body JSON de login/recuperacion.
 */
function conexion_leer_ubicacion($entrada) {
    return array(
        'locationLong' => (isset($entrada['location_long']) && $entrada['location_long'] !== '')
            ? limpiar_texto($entrada['location_long']) : '0',
        'locationLat' => (isset($entrada['location_lat']) && $entrada['location_lat'] !== '')
            ? limpiar_texto($entrada['location_lat']) : '0',
        'sucursalId' => isset($entrada['sucursal_id']) ? (int) $entrada['sucursal_id'] : 0,
    );
}

/**
 * Busca un usuario por email en tenants con ciertos estados.
 */
function conexion_buscar_usuario_por_email($conexionControl, $email, $estadosTenant) {
    if (count($estadosTenant) === 0) {
        return null;
    }

    $marcadores = implode(',', array_fill(0, count($estadosTenant), '?'));
    $tipos = str_repeat('s', count($estadosTenant));
    $tenants = db_consultar(
        $conexionControl,
        "SELECT * FROM tenants WHERE estado IN ($marcadores)",
        $tipos,
        $estadosTenant
    );

    $tenantEncontrado = null;
    $usuarioEncontrado = null;
    $conexionTenant = null;

    foreach ($tenants as $candidato) {
        $conexionCandidata = db_conectar_tenant($candidato);

        $usuarios = db_consultar(
            $conexionCandidata,
            "SELECT id, nombre, apellidos, email, password_hash, role_id, estado
             FROM usuarios WHERE email = ? LIMIT 1",
            's',
            array($email)
        );

        if (count($usuarios) === 0) {
            continue;
        }

        if ($tenantEncontrado !== null) {
            return array('duplicado' => true);
        }

        $tenantEncontrado = $candidato;
        $usuarioEncontrado = $usuarios[0];
        $conexionTenant = $conexionCandidata;
    }

    if ($tenantEncontrado === null) {
        return null;
    }

    return array(
        'tenant' => $tenantEncontrado,
        'usuario' => $usuarioEncontrado,
        'conexionTenant' => $conexionTenant,
    );
}
