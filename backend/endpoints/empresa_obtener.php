<?php
// ============================================================================
// GET /api/empresa/obtener
// Cabecera: Authorization: Bearer <token>
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'empresa.ver');

$filas = db_consultar(
    $conexionTenant,
    "SELECT ec.*, p.nombre AS pais_nombre, iv.nombre AS regimen_iva_nombre, iv.porcentaje AS regimen_iva_porcentaje
     FROM empresa_configuracion ec
     LEFT JOIN paises p ON p.id = ec.pais_id
     LEFT JOIN iva_tipos iv ON iv.id = ec.regimen_iva_id
     LIMIT 1"
);

if (count($filas) === 0) {
    responder_error('La empresa aun no tiene configuracion registrada', 404);
}

responder_json($filas[0]);
