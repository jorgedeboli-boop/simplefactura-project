<?php
// ============================================================================
// PUT/POST /api/clientes/actualizar
// Cabecera: Authorization: Bearer <token>
// Body: { id, tipo?, nombre_razon_social, identificacion_fiscal?, pais_id,
//         direccion?, ciudad?, provincia_estado?, codigo_postal?, telefono?,
//         email?, persona_contacto?, notas?, estado? }
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'PUT' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'clientes.editar');

$entrada = leer_json_entrada();
validar_campos_requeridos($entrada, array('id', 'nombre_razon_social', 'pais_id'));

$id = (int) $entrada['id'];

$tipo = isset($entrada['tipo']) && in_array($entrada['tipo'], array('particular', 'empresa'), true)
    ? $entrada['tipo']
    : 'empresa';

if (isset($entrada['email']) && $entrada['email'] !== '' && !validar_email($entrada['email'])) {
    responder_error('El email no tiene un formato valido', 400);
}

if (isset($entrada['estado']) && !in_array($entrada['estado'], array('activo', 'inactivo'), true)) {
    responder_error('Estado no valido', 400);
}

$estado = isset($entrada['estado']) ? $entrada['estado'] : 'activo';

$resultado = db_ejecutar(
    $conexionTenant,
    "UPDATE clientes SET
        tipo = ?,
        nombre_razon_social = ?,
        identificacion_fiscal = ?,
        pais_id = ?,
        direccion = ?,
        ciudad = ?,
        provincia_estado = ?,
        codigo_postal = ?,
        telefono = ?,
        email = ?,
        persona_contacto = ?,
        notas = ?,
        estado = ?
     WHERE id = ?",
    'sssisssssssssi',
    array(
        $tipo,
        limpiar_texto($entrada['nombre_razon_social']),
        isset($entrada['identificacion_fiscal']) ? limpiar_texto($entrada['identificacion_fiscal']) : null,
        (int) $entrada['pais_id'],
        isset($entrada['direccion']) ? limpiar_texto($entrada['direccion']) : null,
        isset($entrada['ciudad']) ? limpiar_texto($entrada['ciudad']) : null,
        isset($entrada['provincia_estado']) ? limpiar_texto($entrada['provincia_estado']) : null,
        isset($entrada['codigo_postal']) ? limpiar_texto($entrada['codigo_postal']) : null,
        isset($entrada['telefono']) ? limpiar_texto($entrada['telefono']) : null,
        isset($entrada['email']) ? limpiar_texto($entrada['email']) : null,
        isset($entrada['persona_contacto']) ? limpiar_texto($entrada['persona_contacto']) : null,
        isset($entrada['notas']) ? limpiar_texto($entrada['notas']) : null,
        $estado,
        $id,
    )
);

if ($resultado['filas_afectadas'] === 0) {
    responder_error('Cliente no encontrado', 404);
}

$clientes = db_consultar(
    $conexionTenant,
    "SELECT c.*, p.nombre AS pais_nombre
     FROM clientes c
     LEFT JOIN paises p ON p.id = c.pais_id
     WHERE c.id = ?
     LIMIT 1",
    'i',
    array($id)
);

if (count($clientes) === 0) {
    responder_error('Cliente no encontrado', 404);
}

responder_json($clientes[0]);
