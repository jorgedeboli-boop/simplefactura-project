<?php
// ============================================================================
// Simple Factura - Plantillas HTML de factura y utilidades de upload
// ============================================================================

require_once __DIR__ . '/../config/constantes.php';

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
 * URL publica de un archivo subido del tenant.
 */
function sf_url_upload_tenant($identificadorTenant, $nombreArchivo) {
    $identificador = preg_replace('/[^a-zA-Z0-9_-]/', '', (string) $identificadorTenant);
    $archivo = rawurlencode((string) $nombreArchivo);
    return rtrim(SF_APP_URL, '/') . '/api/uploads/' . $identificador . '/' . $archivo;
}

/**
 * Valida y normaliza un color hexadecimal (#RGB o #RRGGBB).
 */
function sf_normalizar_color_hex($color) {
    $color = trim((string) $color);
    if (!preg_match('/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/', $color)) {
        return null;
    }
    if (strlen($color) === 4) {
        $r = $color[1];
        $g = $color[2];
        $b = $color[3];
        return '#' . $r . $r . $g . $g . $b . $b;
    }
    return strtolower($color);
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
 * Enriquece la fila de empresa_configuracion con URL del logo subido.
 */
function sf_enriquecer_empresa_logotipo($fila, $identificadorTenant) {
    if (!empty($fila['logotipo_file'])) {
        $fila['logotipo_archivo_url'] = sf_url_upload_tenant(
            $identificadorTenant,
            $fila['logotipo_file']
        );
    } else {
        $fila['logotipo_archivo_url'] = null;
    }
    return $fila;
}
