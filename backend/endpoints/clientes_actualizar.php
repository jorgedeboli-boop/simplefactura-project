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

$existentes = db_consultar(
    $conexionTenant,
    "SELECT id FROM clientes WHERE id = ? LIMIT 1",
    'i',
    array($id)
);
if (count($existentes) === 0) {
    responder_error('Cliente no encontrado', 404);
}

$tipo = isset($entrada['tipo']) && in_array($entrada['tipo'], array('particular', 'empresa'), true)
    ? $entrada['tipo']
    : 'empresa';

$email = contacto_texto_opcional(isset($entrada['email']) ? $entrada['email'] : null);
if ($email !== null && !validar_email($email)) {
    responder_error('El email no tiene un formato valido', 400);
}

if (isset($entrada['estado']) && !in_array($entrada['estado'], array('activo', 'inactivo'), true)) {
    responder_error('Estado no valido', 400);
}

$estado = isset($entrada['estado']) ? $entrada['estado'] : 'activo';
$paisId = (int) $entrada['pais_id'];

$paises = db_consultar(
    $conexionTenant,
    "SELECT id FROM paises WHERE id = ? LIMIT 1",
    'i',
    array($paisId)
);
if (count($paises) === 0) {
    responder_error('Pais no encontrado', 400);
}

db_ejecutar(
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
        contacto_texto_opcional(isset($entrada['identificacion_fiscal']) ? $entrada['identificacion_fiscal'] : null),
        $paisId,
        contacto_texto_opcional(isset($entrada['direccion']) ? $entrada['direccion'] : null),
        contacto_texto_opcional(isset($entrada['ciudad']) ? $entrada['ciudad'] : null),
        contacto_texto_opcional(isset($entrada['provincia_estado']) ? $entrada['provincia_estado'] : null),
        contacto_texto_opcional(isset($entrada['codigo_postal']) ? $entrada['codigo_postal'] : null),
        contacto_texto_opcional(isset($entrada['telefono']) ? $entrada['telefono'] : null),
        $email,
        contacto_texto_opcional(isset($entrada['persona_contacto']) ? $entrada['persona_contacto'] : null),
        contacto_texto_opcional(isset($entrada['notas']) ? $entrada['notas'] : null),
        $estado,
        $id,
    )
);

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
