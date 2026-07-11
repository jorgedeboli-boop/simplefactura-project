<?php
// ============================================================================
// PUT/POST /api/empresa/actualizar
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

if (count($entrada) === 0) {
    responder_error(
        'No se recibieron datos. Si el hosting bloquea PUT, la app debe usar POST.',
        400
    );
}

// Campos editables (whitelist explicita para evitar actualizar columnas no permitidas)
$camposPermitidos = array(
    'razon_social', 'nombre_comercial', 'identificacion_fiscal', 'tipo_empresa', 'pais_id',
    'direccion', 'ciudad', 'provincia_estado', 'codigo_postal',
    'telefono_principal', 'telefono_secundario', 'email_corporativo',
    'email_facturacion', 'sitio_web', 'moneda_codigo', 'regimen_iva_id',
    'logotipo_url', 'logotipo_file', 'color_primario', 'factura_design', 'color_design',
    'iban_cuenta',
);

$columnasPersonalizacion = array('logotipo_file', 'factura_design', 'color_design');
$columnasSolicitadas = array();
foreach ($columnasPersonalizacion as $columna) {
    if (array_key_exists($columna, $entrada)) {
        $columnasSolicitadas[] = $columna;
    }
}
if (count($columnasSolicitadas) > 0) {
    $faltantes = sf_tenant_columnas_faltantes(
        $conexionTenant,
        'empresa_configuracion',
        $columnasSolicitadas
    );
    if (count($faltantes) > 0) {
        responder_error(
            'Faltan columnas en la BD del tenant: ' . implode(', ', $faltantes)
            . '. Ejecute database/07_empresa_factura_personalizacion.sql',
            503
        );
    }
}

$tiposValidosEmpresa = array('autonomo', 'sl', 'slu');

$sets = array();
$tipos = '';
$valores = array();

foreach ($camposPermitidos as $campo) {
    if (!array_key_exists($campo, $entrada)) {
        continue;
    }

    if ($campo === 'tipo_empresa') {
        $tipo = limpiar_texto($entrada[$campo]);
        if (!in_array($tipo, $tiposValidosEmpresa, true)) {
            responder_error('Tipo de empresa no valido', 400);
        }
        $sets[] = "$campo = ?";
        $tipos .= 's';
        $valores[] = $tipo;
        continue;
    }

    if ($campo === 'factura_design') {
        $diseno = (int) $entrada[$campo];
        if ($diseno < 1 || $diseno > 3) {
            responder_error('El diseno de factura debe ser 1, 2 o 3', 400);
        }
        $sets[] = "$campo = ?";
        $tipos .= 's';
        $valores[] = (string) $diseno;
        continue;
    }

    if ($campo === 'color_design') {
        $color = sf_normalizar_color_hex($entrada[$campo]);
        if ($color === null) {
            responder_error('Color de diseno no valido', 400);
        }
        $sets[] = "$campo = ?";
        $tipos .= 's';
        $valores[] = $color;
        continue;
    }

    $sets[] = "$campo = ?";
    $tipos .= 's';
    $valores[] = limpiar_texto($entrada[$campo]);
}

if (count($sets) === 0) {
    responder_error('No se recibio ningun campo para actualizar', 400);
}

$sql = "UPDATE empresa_configuracion SET " . implode(', ', $sets) . " LIMIT 1";
db_ejecutar($conexionTenant, $sql, $tipos, $valores);

responder_json(array('mensaje' => 'Configuracion de empresa actualizada'));
