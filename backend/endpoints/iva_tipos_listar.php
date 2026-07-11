<?php
// ============================================================================
// GET /api/iva_tipos/listar?pais_id=1
// Cabecera: Authorization: Bearer <token>
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

$paisId = isset($_GET['pais_id']) ? (int) $_GET['pais_id'] : null;

if ($paisId) {
    $tipos = db_consultar(
        $conexionTenant,
        "SELECT id, pais_id, nombre, porcentaje, es_default
         FROM iva_tipos WHERE pais_id = ? ORDER BY porcentaje DESC",
        'i',
        array($paisId)
    );
} else {
    $tipos = db_consultar(
        $conexionTenant,
        "SELECT id, pais_id, nombre, porcentaje, es_default
         FROM iva_tipos ORDER BY pais_id ASC, porcentaje DESC"
    );
}

responder_json($tipos);
