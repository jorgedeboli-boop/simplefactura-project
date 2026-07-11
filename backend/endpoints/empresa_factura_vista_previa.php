<?php
// ============================================================================
// GET /api/empresa/factura/vista-previa?diseno=1&color=%23398bf7
// Devuelve HTML renderizado de la plantilla seleccionada.
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Metodo no permitido', 405);
}

require_once __DIR__ . '/../lib/plantilla_factura.php';

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);
$identificadorTenant = $sesion['tenant']['identificador'];

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'empresa.ver');

$diseno = isset($_GET['diseno']) ? (int) $_GET['diseno'] : 1;
$color = isset($_GET['color']) ? urldecode((string) $_GET['color']) : '#398bf7';

// SELECT * tolera tenants sin migracion de columnas nuevas.
$filas = db_consultar(
    $conexionTenant,
    'SELECT * FROM empresa_configuracion LIMIT 1'
);

$logoUrl = null;
if (count($filas) > 0) {
    $fila = $filas[0];
    if (!empty($fila['logotipo_file'])) {
        $logoUrl = sf_url_upload_tenant($identificadorTenant, $fila['logotipo_file']);
    }

    if (!isset($_GET['color']) && !empty($fila['color_design'])) {
        $color = $fila['color_design'];
    }

    if (!isset($_GET['diseno']) && !empty($fila['factura_design'])) {
        $diseno = (int) $fila['factura_design'];
    }
}

try {
    $html = sf_renderizar_plantilla_factura($diseno, $color, $logoUrl);
} catch (Throwable $e) {
    $detalle = defined('SF_DEBUG') && SF_DEBUG ? $e->getMessage() : '';
    http_response_code(500);
    header('Content-Type: text/html; charset=UTF-8');
    echo '<!DOCTYPE html><html><body style="font-family:sans-serif;padding:24px;">'
        . '<h3>No se pudo generar la vista previa</h3>'
        . '<p>Comprueba que las plantillas esten desplegadas en el servidor.</p>'
        . ($detalle !== '' ? '<pre>' . htmlspecialchars($detalle) . '</pre>' : '')
        . '</body></html>';
    exit;
}

header('Content-Type: text/html; charset=UTF-8');
echo $html;
exit;
