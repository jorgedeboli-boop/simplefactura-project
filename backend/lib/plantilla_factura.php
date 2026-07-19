<?php
// ============================================================================
// Simple Factura - Plantillas HTML de factura y utilidades de upload
// ============================================================================

if (!defined('SF_UPLOADS_DIR')) {
    define('SF_UPLOADS_DIR', dirname(__DIR__) . '/uploads');
}

/**
 * Ruta absoluta de la carpeta de uploads del tenant.
 */
function sf_ruta_uploads_tenant($identificadorTenant) {
    $identificador = preg_replace('/[^a-zA-Z0-9_-]/', '', (string) $identificadorTenant);
    return rtrim(SF_UPLOADS_DIR, '/\\') . DIRECTORY_SEPARATOR . $identificador;
}

/**
 * Carga una plantilla de factura (1-3) e inyecta color y logo.
 */
function sf_renderizar_plantilla_factura($numeroDiseno, $colorHex, $logoUrl = null) {
    $numeroDiseno = (int) $numeroDiseno;
    if ($numeroDiseno < 1 || $numeroDiseno > 3) {
        $numeroDiseno = 1;
    }

    $color = sf_normalizar_color_hex($colorHex);
    if ($color === null) {
        $color = '#398bf7';
    }

    $ruta = __DIR__ . '/../plantillas_factura/diseno_' . $numeroDiseno . '.html';
    if (!is_readable($ruta)) {
        throw new RuntimeException('Plantilla de factura no encontrada: diseno_' . $numeroDiseno);
    }

    $html = file_get_contents($ruta);

    $html = preg_replace(
        '/--color-primary:\s*#[0-9a-fA-F]{3,8}/',
        '--color-primary: ' . $color,
        $html,
        1
    );

    if ($logoUrl) {
        $logoHtml = '<img src="' . htmlspecialchars($logoUrl, ENT_QUOTES, 'UTF-8') . '" alt="Logo" style="max-height:48px;max-width:220px;object-fit:contain;">';
        $html = sf_inyectar_logo_plantilla($html, $numeroDiseno, $logoHtml);
    }

    return $html;
}

/**
 * Sustituye el bloque de logo por defecto en cada diseno.
 */
function sf_inyectar_logo_plantilla($html, $numeroDiseno, $logoHtml) {
    switch ((int) $numeroDiseno) {
        case 1:
            return preg_replace(
                '/(<div class="marca">)(.*?)(<\/div>\s*<div class="datos-empresa">)/s',
                '$1' . $logoHtml . '$3',
                $html,
                1
            );
        case 2:
            return preg_replace(
                '/(<div class="barra-superior">\s*<div class="marca">)(.*?)(<\/div>\s*<div class="contacto-rapido">)/s',
                '$1' . $logoHtml . '$3',
                $html,
                1
            );
        case 3:
            return preg_replace(
                '/(<div class="encabezado">\s*<div class="logo">)(.*?)(<\/div>\s*<div class="barra-verde">)/s',
                '$1' . $logoHtml . '$3',
                $html,
                1
            );
        default:
            return $html;
    }
}

/**
 * Extensiones permitidas para logotipos.
 */
function sf_extensiones_logotipo_permitidas() {
    return array('png', 'jpg', 'jpeg', 'gif', 'webp', 'svg');
}

/**
 * Guarda bytes de logotipo en la carpeta del tenant y devuelve el nombre final.
 */
function sf_guardar_logotipo_tenant($identificadorTenant, $bytes, $nombreOriginal) {
    $extension = strtolower(pathinfo((string) $nombreOriginal, PATHINFO_EXTENSION));
    if (!in_array($extension, sf_extensiones_logotipo_permitidas(), true)) {
        responder_error('Formato de imagen no permitido. Use PNG, JPG, GIF, WEBP o SVG.', 400);
    }

    if (strlen($bytes) > 2 * 1024 * 1024) {
        responder_error('El logotipo no puede superar 2 MB', 400);
    }

    $directorio = sf_ruta_uploads_tenant($identificadorTenant);
    if (!is_dir($directorio) && !mkdir($directorio, 0755, true) && !is_dir($directorio)) {
        responder_error('No se pudo crear la carpeta de uploads', 500);
    }

    $nombreFinal = 'logo_' . date('Ymd_His') . '_' . bin2hex(random_bytes(4)) . '.' . $extension;
    $rutaFinal = $directorio . DIRECTORY_SEPARATOR . $nombreFinal;

    if (file_put_contents($rutaFinal, $bytes) === false) {
        responder_error('No se pudo guardar el logotipo', 500);
    }

    return $nombreFinal;
}

/**
 * Genera HTML imprimible de una factura con datos reales y estilo de plantilla.
 */
function sf_html_factura_imprimible($factura, $lineas, $empresa, $logoUrl = null) {
    $color = sf_normalizar_color_hex(
        !empty($empresa['color_design']) ? $empresa['color_design'] : (
            !empty($empresa['color_primario']) ? $empresa['color_primario'] : '#398bf7'
        )
    );
    if ($color === null) {
        $color = '#398bf7';
    }

    $esc = function ($v) {
        return htmlspecialchars((string) $v, ENT_QUOTES, 'UTF-8');
    };

    $fmtFecha = function ($fecha) {
        if ($fecha === null || $fecha === '') {
            return '—';
        }
        $ts = strtotime($fecha);
        return $ts ? date('d/m/Y', $ts) : $fecha;
    };

    $fmtMoney = function ($n, $moneda) use ($esc) {
        return $esc(number_format((float) $n, 2, ',', '.') . ' ' . $moneda);
    };

    $razon = !empty($empresa['nombre_comercial'])
        ? $empresa['nombre_comercial']
        : (isset($empresa['razon_social']) ? $empresa['razon_social'] : 'Empresa');
    $moneda = isset($factura['moneda_codigo']) ? $factura['moneda_codigo'] : 'EUR';
    $numero = (isset($factura['serie']) ? $factura['serie'] . '-' : '')
        . (isset($factura['numero_factura']) ? $factura['numero_factura'] : '');

    $dirEmpresa = trim(implode(', ', array_filter(array(
        isset($empresa['direccion']) ? $empresa['direccion'] : null,
        isset($empresa['codigo_postal']) ? $empresa['codigo_postal'] : null,
        isset($empresa['ciudad']) ? $empresa['ciudad'] : null,
    ))));

    $contactoEmpresa = trim(implode(' · ', array_filter(array(
        !empty($empresa['telefono_principal']) ? 'Tel: ' . $empresa['telefono_principal'] : null,
        !empty($empresa['email_facturacion'])
            ? $empresa['email_facturacion']
            : (!empty($empresa['email_corporativo']) ? $empresa['email_corporativo'] : null),
    ))));

    $clienteNombre = isset($factura['cliente_nombre']) && $factura['cliente_nombre'] !== ''
        ? $factura['cliente_nombre']
        : 'Cliente';
    $clienteDir = trim(implode(', ', array_filter(array(
        isset($factura['cliente_direccion']) ? $factura['cliente_direccion'] : null,
        isset($factura['cliente_ciudad']) ? $factura['cliente_ciudad'] : null,
    ))));
    $clienteTel = isset($factura['cliente_telefono']) ? $factura['cliente_telefono'] : '';
    $clienteEmail = isset($factura['cliente_email']) ? $factura['cliente_email'] : '';
    $clienteNif = isset($factura['cliente_identificacion_fiscal'])
        ? $factura['cliente_identificacion_fiscal']
        : '';

    $logoHtml = $logoUrl
        ? '<img src="' . $esc($logoUrl) . '" alt="Logo" style="max-height:52px;max-width:220px;object-fit:contain;">'
        : '<div style="font-size:18px;font-weight:700;color:#1c2733;">' . $esc($razon) . '</div>';

    $filas = '';
    if (is_array($lineas)) {
        foreach ($lineas as $i => $linea) {
            $bg = ($i % 2 === 0) ? '#f7f9fb' : '#ffffff';
            $ivaTxt = isset($linea['iva_porcentaje'])
                ? number_format((float) $linea['iva_porcentaje'], 0) . '%'
                : (isset($linea['iva_tipo_nombre']) ? $linea['iva_tipo_nombre'] : '');
            $filas .= '<tr style="background:' . $bg . ';">'
                . '<td style="padding:10px 12px;border-bottom:1px solid #eef1f4;">' . $esc($linea['descripcion']) . '</td>'
                . '<td style="padding:10px 12px;border-bottom:1px solid #eef1f4;text-align:center;">'
                . $esc(number_format((float) $linea['cantidad'], 2, ',', '.')) . '</td>'
                . '<td style="padding:10px 12px;border-bottom:1px solid #eef1f4;text-align:right;">'
                . $fmtMoney($linea['precio_unitario'], $moneda) . '</td>'
                . '<td style="padding:10px 12px;border-bottom:1px solid #eef1f4;text-align:center;">' . $esc($ivaTxt) . '</td>'
                . '<td style="padding:10px 12px;border-bottom:1px solid #eef1f4;text-align:right;font-weight:600;">'
                . $fmtMoney($linea['importe_linea'], $moneda) . '</td>'
                . '</tr>';
        }
    }

    if ($filas === '') {
        $filas = '<tr><td colspan="5" style="padding:16px;color:#888;">Sin líneas</td></tr>';
    }

    $notas = !empty($factura['notas'])
        ? '<div style="margin-top:24px;"><div style="font-size:12px;font-weight:600;color:#1c2733;margin-bottom:4px;">Notas</div>'
            . '<div style="font-size:12px;color:#5a6570;white-space:pre-wrap;">' . $esc($factura['notas']) . '</div></div>'
        : '';

    $html = '<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8">'
        . '<title>Factura ' . $esc($numero) . '</title>'
        . '<style>
body{margin:0;background:#e8ecf0;font-family:Helvetica,Arial,sans-serif;color:#5a6570;}
.hoja{width:210mm;min-height:297mm;margin:16px auto;background:#fff;padding:14mm;box-sizing:border-box;}
.barra{height:6px;background:' . $esc($color) . ';margin:12px 0 20px;}
.encabezado{display:flex;justify-content:space-between;gap:24px;align-items:flex-start;}
.empresa-datos{font-size:12px;line-height:1.5;text-align:right;max-width:280px;}
.meta{display:flex;justify-content:space-between;gap:24px;margin:28px 0;}
.bloque h3{margin:0 0 8px;font-size:12px;letter-spacing:1px;color:' . $esc($color) . ';}
.cliente-nombre{font-size:15px;font-weight:700;color:#1c2733;margin-bottom:6px;}
.dato{font-size:12px;margin:3px 0;}
.titulo-doc{font-size:28px;font-weight:800;color:#1c2733;margin:0 0 10px;}
.fila-dato{font-size:12px;margin:4px 0;}
.fila-dato b{color:#1c2733;}
table.items{width:100%;border-collapse:collapse;margin-top:8px;font-size:12px;}
table.items th{background:' . $esc($color) . ';color:#fff;text-align:left;padding:10px 12px;font-weight:600;}
.totales{width:280px;margin-left:auto;margin-top:20px;}
.totales .fila{display:flex;justify-content:space-between;padding:6px 0;font-size:13px;}
.totales .total{display:flex;margin-top:8px;}
.totales .total .e{flex:1;background:#2c3340;color:#fff;padding:10px 14px;font-weight:700;}
.totales .total .v{background:' . $esc($color) . ';color:#fff;padding:10px 14px;font-weight:700;min-width:110px;text-align:right;}
@media print{body{background:#fff;} .hoja{margin:0;box-shadow:none;}}
</style></head><body><div class="hoja">'
        . '<div class="encabezado"><div>' . $logoHtml . '</div>'
        . '<div class="empresa-datos"><strong style="color:#1c2733;font-size:14px;">' . $esc($razon) . '</strong><br>'
        . $esc($dirEmpresa) . '<br>' . $esc($contactoEmpresa);
    if (!empty($empresa['identificacion_fiscal'])) {
        $html .= '<br>NIF/CIF: ' . $esc($empresa['identificacion_fiscal']);
    }
    $html .= '</div></div><div class="barra"></div>'
        . '<div class="meta"><div class="bloque">'
        . '<h3>FACTURAR A</h3>'
        . '<div class="cliente-nombre">' . $esc($clienteNombre) . '</div>';
    if ($clienteNif !== '') {
        $html .= '<div class="dato">NIF/CIF: ' . $esc($clienteNif) . '</div>';
    }
    if ($clienteDir !== '') {
        $html .= '<div class="dato">' . $esc($clienteDir) . '</div>';
    }
    if ($clienteTel !== '') {
        $html .= '<div class="dato">Tel: ' . $esc($clienteTel) . '</div>';
    }
    if ($clienteEmail !== '') {
        $html .= '<div class="dato">' . $esc($clienteEmail) . '</div>';
    }
    $html .= '</div><div class="bloque" style="text-align:right;">'
        . '<div class="titulo-doc">FACTURA</div>'
        . '<div class="fila-dato"><b>Nº:</b> ' . $esc($numero) . '</div>'
        . '<div class="fila-dato"><b>Fecha:</b> ' . $esc($fmtFecha($factura['fecha_emision'])) . '</div>';
    if (!empty($factura['fecha_vencimiento'])) {
        $html .= '<div class="fila-dato"><b>Vencimiento:</b> ' . $esc($fmtFecha($factura['fecha_vencimiento'])) . '</div>';
    }
    if (!empty($factura['forma_pago'])) {
        $html .= '<div class="fila-dato"><b>Forma de pago:</b> ' . $esc($factura['forma_pago']) . '</div>';
    }
    $html .= '</div></div>'
        . '<table class="items"><thead><tr>'
        . '<th>Descripción</th><th style="text-align:center;">Cant.</th>'
        . '<th style="text-align:right;">Precio</th><th style="text-align:center;">IVA</th>'
        . '<th style="text-align:right;">Importe</th></tr></thead><tbody>'
        . $filas . '</tbody></table>'
        . '<div class="totales">'
        . '<div class="fila"><span>Subtotal</span><span>' . $fmtMoney($factura['subtotal'], $moneda) . '</span></div>'
        . '<div class="fila"><span>IVA</span><span>' . $fmtMoney($factura['total_iva'], $moneda) . '</span></div>'
        . '<div class="total"><div class="e">TOTAL</div><div class="v">' . $fmtMoney($factura['total'], $moneda) . '</div></div>'
        . '</div>'
        . $notas
        . '</div><script>window.onload=function(){setTimeout(function(){window.print();},250);};</script>'
        . '</body></html>';

    return $html;
}
