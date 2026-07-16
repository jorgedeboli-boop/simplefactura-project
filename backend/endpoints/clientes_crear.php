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

$tipo = isset($entrada['tipo']) && in_array($entrada['tipo'], array('particular', 'empresa'))
    ? $entrada['tipo']
    : 'empresa';

if (isset($entrada['email']) && $entrada['email'] !== '' && !validar_email($entrada['email'])) {
    responder_error('El email no tiene un formato valido', 400);
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
    )
);

responder_json(array(
    'id'      => $resultado['id_insertado'],
    'mensaje' => 'Cliente creado correctamente',
), 201);
