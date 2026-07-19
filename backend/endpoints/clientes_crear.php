<?php
// ============================================================================
// POST /api/clientes/crear
// Cabecera: Authorization: Bearer <token>
// Body: { tipo, nombre_razon_social, identificacion_fiscal, pais_id, direccion,
//         ciudad, provincia_estado, codigo_postal, telefono, email, persona_contacto, notas }
// ============================================================================

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    responder_error('Metodo no permitido', 405);
}

$sesion = auth_requerir_sesion();
$conexionTenant = db_conectar_tenant($sesion['tenant']);

auth_requerir_permiso($conexionTenant, $sesion['usuario_id'], 'clientes.crear');

$entrada = leer_json_entrada();
validar_campos_requeridos($entrada, array('nombre_razon_social', 'pais_id'));

$tipo = isset($entrada['tipo']) && in_array($entrada['tipo'], array('particular', 'empresa'), true)
    ? $entrada['tipo']
    : 'empresa';

$email = contacto_texto_opcional(isset($entrada['email']) ? $entrada['email'] : null);
if ($email !== null && !validar_email($email)) {
    responder_error('El email no tiene un formato valido', 400);
}

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

$resultado = db_ejecutar(
    $conexionTenant,
    "INSERT INTO clientes
        (tipo, nombre_razon_social, identificacion_fiscal, pais_id, direccion,
         ciudad, provincia_estado, codigo_postal, telefono, email, persona_contacto, notas, estado)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'activo')",
    'sssissssssss',
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
    )
);

responder_json(array(
    'id'      => $resultado['id_insertado'],
    'mensaje' => 'Cliente creado correctamente',
), 201);
