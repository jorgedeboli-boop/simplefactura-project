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
$color = isset($_GET['color']) ? (string) $_GET['color'] : '#398bf7';

$filas = db_consultar(
    $conexionTenant,
    'SELECT logotipo_file, color_design, factura_design FROM empresa_configuracion LIMIT 1'
);

$logoUrl = null;
if (count($filas) > 0 && !empty($filas[0]['logotipo_file'])) {
    $logoUrl = sf_url_upload_tenant($identificadorTenant, $filas[0]['logotipo_file']);
}

if (!isset($_GET['color']) && count($filas) > 0 && !empty($filas[0]['color_design'])) {
    $color = $filas[0]['color_design'];
}

if (!isset($_GET['diseno']) && count($filas) > 0 && !empty($filas[0]['factura_design'])) {
    $diseno = (int) $filas[0]['factura_design'];
}

$html = sf_renderizar_plantilla_factura($diseno, $color, $logoUrl);

header('Content-Type: text/html; charset=UTF-8');
echo $html;
exit;
