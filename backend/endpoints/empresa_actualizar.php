<?php
// ============================================================================
// PUT /api/empresa/actualizar
// Cabecera: Authorization: Bearer <token>
// Body: campos de empresa_configuracion a actualizar (parcial)
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'PUT' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'empresa.editar');

$entrada = leer_json_entrada();

// Campos editables (whitelist explicita para evitar actualizar columnas no permitidas)
$camposPermitidos = array(
    'razon_social', 'nombre_comercial', 'identificacion_fiscal', 'pais_id',
    'direccion', 'ciudad', 'provincia_estado', 'codigo_postal',
    'telefono_principal', 'telefono_secundario', 'email_corporativo',
    'email_facturacion', 'sitio_web', 'moneda_codigo', 'regimen_iva_id',
    'logotipo_url', 'color_primario', 'iban_cuenta',
);

$sets = array();
$tipos = '';
$valores = array();

foreach ($camposPermitidos as $campo) {
    if (array_key_exists($campo, $entrada)) {
        $sets[] = "$campo = ?";
        $tipos .= 's';
        $valores[] = limpiar_texto($entrada[$campo]);
    }
}

if (count($sets) === 0) {
    responder_error('No se recibio ningun campo para actualizar', 400);
}

$sql = "UPDATE empresa_configuracion SET " . implode(', ', $sets) . " LIMIT 1";
db_ejecutar($conexionTenant, $sql, $tipos, $valores);

responder_json(array('mensaje' => 'Configuracion de empresa actualizada'));
