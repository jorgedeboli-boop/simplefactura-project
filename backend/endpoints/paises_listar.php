<?php
// ============================================================================
// GET /api/paises/listar
// Cabecera: Authorization: Bearer <token>
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

$paises = db_consultar(
    $conexionTenant,
    "SELECT id, codigo_iso2, nombre, moneda_codigo, moneda_nombre, moneda_simbolo
     FROM paises ORDER BY nombre ASC"
);

responder_json($paises);
