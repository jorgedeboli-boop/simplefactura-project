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
