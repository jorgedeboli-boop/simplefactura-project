<?php
// ============================================================================
// POST /api/empresa/logotipo/subir
// Body JSON: { "nombre_archivo": "logo.png", "contenido_base64": "..." }
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    responder_error('Metodo no permitido', 405);
}

require_once __DIR__ . '/../lib/plantilla_factura.php';

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);
$identificadorTenant = $sesion['tenant']['identificador'];

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'empresa.editar');

$entrada = leer_json_entrada();

$nombreArchivo = isset($entrada['nombre_archivo']) ? limpiar_texto($entrada['nombre_archivo']) : '';
$contenidoBase64 = isset($entrada['contenido_base64']) ? (string) $entrada['contenido_base64'] : '';

if ($nombreArchivo === '' || $contenidoBase64 === '') {
    responder_error('nombre_archivo y contenido_base64 son obligatorios', 400);
}

if (strpos($contenidoBase64, ',') !== false) {
    $partes = explode(',', $contenidoBase64, 2);
    $contenidoBase64 = $partes[1];
}

$bytes = base64_decode($contenidoBase64, true);
if ($bytes === false || strlen($bytes) === 0) {
    responder_error('contenido_base64 invalido', 400);
}

$nombreFinal = sf_guardar_logotipo_tenant($identificadorTenant, $bytes, $nombreArchivo);

db_ejecutar(
    $conexionTenant,
    'UPDATE empresa_configuracion SET logotipo_file = ? LIMIT 1',
    's',
    array($nombreFinal)
);

$url = sf_url_upload_tenant($identificadorTenant, $nombreFinal);

responder_json(array(
    'mensaje' => 'Logotipo subido correctamente',
    'logotipo_file' => $nombreFinal,
    'logotipo_archivo_url' => $url,
));
