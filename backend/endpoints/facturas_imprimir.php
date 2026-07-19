<?php
// ============================================================================
// GET /api/facturas/imprimir?id=123
// Devuelve HTML listo para imprimir (plantilla con datos reales).
// Cabecera: Authorization: Bearer <token>
// ============================================================================

require_once __DIR__ . '/../lib/plantilla_factura.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'facturas.ver');

$id = isset($_GET['id']) ? (int) $_GET['id'] : 0;
if ($id <= 0) {
    responder_error('id de factura requerido', 400);
}

$factura = documento_obtener_factura_completa($conexionTenant, $id);
if ($factura === null) {
    responder_error('Factura no encontrada', 404);
}

// Ampliar datos del cliente para la plantilla.
if (!empty($factura['cliente_id'])) {
    $clientes = db_consultar(
        $conexionTenant,
        "SELECT nombre_razon_social, identificacion_fiscal, direccion, ciudad,
                provincia_estado, codigo_postal, telefono, email
         FROM clientes WHERE id = ? LIMIT 1",
        'i',
        array((int) $factura['cliente_id'])
    );
    if (count($clientes) > 0) {
        $c = $clientes[0];
        $factura['cliente_nombre'] = $c['nombre_razon_social'];
        $factura['cliente_identificacion_fiscal'] = $c['identificacion_fiscal'];
        $factura['cliente_direccion'] = $c['direccion'];
        $factura['cliente_ciudad'] = trim(implode(' ', array_filter(array(
            $c['codigo_postal'],
            $c['ciudad'],
            $c['provincia_estado'],
        ))));
        $factura['cliente_telefono'] = $c['telefono'];
        $factura['cliente_email'] = $c['email'];
    }
}

$empresas = db_consultar(
    $conexionTenant,
    "SELECT * FROM empresa_configuracion LIMIT 1"
);
if (count($empresas) === 0) {
    responder_error('Configuracion de empresa no encontrada', 404);
}

$empresa = sf_enriquecer_empresa_logotipo($empresas[0], $sesion['tenant']['identificador']);
$logoUrl = !empty($empresa['logotipo_archivo_url']) ? $empresa['logotipo_archivo_url'] : null;

$lineas = isset($factura['lineas']) && is_array($factura['lineas']) ? $factura['lineas'] : array();

$html = sf_html_factura_imprimible($factura, $lineas, $empresa, $logoUrl);

$formato = isset($_GET['formato']) ? $_GET['formato'] : 'html';
if ($formato === 'json') {
    responder_json(array('html' => $html));
}

header('Content-Type: text/html; charset=utf-8');
echo $html;
exit;
