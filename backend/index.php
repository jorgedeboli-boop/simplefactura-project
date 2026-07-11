<?php
// ============================================================================
// Simple Factura - Router de la API
// Estilo funcional, sin clases. Todas las respuestas son JSON.
//
// Uso: /api/index.php?accion=auth_login   (o via .htaccess: /api/auth/login)
// ============================================================================

require_once __DIR__ . '/config/constantes.php';
require_once __DIR__ . '/lib/respuesta.php';
require_once __DIR__ . '/config/db.php';
require_once __DIR__ . '/lib/auth.php';
require_once __DIR__ . '/lib/validacion.php';
require_once __DIR__ . '/lib/utilidades.php';
require_once __DIR__ . '/lib/conexiones.php';

// CORS basico para la app Flutter (ajustar origen en produccion)
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Auth-Token');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// Mapa de acciones -> archivo de endpoint. Cada endpoint nuevo se agrega aqui.
$rutas = array(
    'auth_login'          => 'endpoints/auth_login.php',
    'auth_logout'         => 'endpoints/auth_logout.php',
    'auth_recuperar_password' => 'endpoints/auth_recuperar_password.php',

    'paises_listar'       => 'endpoints/paises_listar.php',
    'iva_tipos_listar'    => 'endpoints/iva_tipos_listar.php',

    'empresa_obtener'     => 'endpoints/empresa_obtener.php',
    'empresa_actualizar'  => 'endpoints/empresa_actualizar.php',

    'usuarios_listar'     => 'endpoints/usuarios_listar.php',
    'usuarios_crear'      => 'endpoints/usuarios_crear.php',
    'usuarios_actualizar' => 'endpoints/usuarios_actualizar.php',
    'usuarios_conexiones_listar' => 'endpoints/usuarios_conexiones_listar.php',
    'roles_listar'        => 'endpoints/roles_listar.php',

    'clientes_listar'     => 'endpoints/clientes_listar.php',
    'clientes_crear'      => 'endpoints/clientes_crear.php',
);

$accion = isset($_GET['accion']) ? $_GET['accion'] : null;

if (!$accion || !isset($rutas[$accion])) {
    responder_error('Accion no encontrada: ' . $accion, 404);
}

require __DIR__ . '/' . $rutas[$accion];
