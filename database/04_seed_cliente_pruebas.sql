-- ============================================================================
-- Simple Factura - Aprovisionamiento manual del CLIENTE DE PRUEBAS
--
-- Pasos para crear un tenant nuevo (esto es lo que en el futuro hara
-- automaticamente la pagina de marketing al recibir un pago):
--   1) Ejecutar 02_tenant_schema.sql sustituyendo {DB_NAME} por el nombre
--      real de la base (aqui: sf_cliente_pruebas)
--   2) Ejecutar 03_seed_paises_iva.sql contra esa misma base
--   3) Ejecutar este archivo (04) contra esa misma base, y la ultima parte
--      contra simplefactura_control
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PARTE 1 - Ejecutar contra la base del tenant: sf_cliente_pruebas
-- ----------------------------------------------------------------------------
USE sf_cliente_pruebas;

-- Datos de la empresa (pais_id = 1 -> España, EUR). Cambiar segun el cliente real.
INSERT INTO empresa_configuracion
    (razon_social, nombre_comercial, identificacion_fiscal, tipo_empresa, pais_id,
     direccion, ciudad, provincia_estado, codigo_postal,
     telefono_principal, email_corporativo, email_facturacion, sitio_web,
     moneda_codigo, regimen_iva_id, logotipo_url, color_primario)
VALUES
    ('Empresa de Pruebas S.L.', 'Simple Factura Demo', 'B00000000', 'sl', 1,
     'Calle Ejemplo 123', 'Madrid', 'Madrid', '28001',
     '+34 900 000 000', 'contacto@empresapruebas.test', 'facturacion@empresapruebas.test',
     'https://empresapruebas.test',
     'EUR',
     (SELECT id FROM iva_tipos WHERE pais_id = 1 AND es_default = 'true' LIMIT 1),
     'https://my.simplefactura.app/assets/cliente_pruebas/logo.svg',
     '#398bf7');

-- Usuario administrador inicial
-- Contraseña de prueba: Prueba1234!
-- IMPORTANTE: este hash bcrypt es solo para arrancar el entorno de pruebas.
-- En produccion, generar siempre el hash con password_hash() en PHP.
INSERT INTO usuarios (nombre, apellidos, email, password_hash, telefono, role_id, estado)
VALUES
    ('Admin', 'Simple Factura', 'admin@empresapruebas.test',
     '$2b$10$iXUZfs9yB1nYO8rlIkROW.pRoamsuxKMojn1KuvuMoO88Nnx0CeIK',
     '+34 900 000 001', 1, 'activo');

-- Cliente de ejemplo
INSERT INTO clientes (tipo, nombre_razon_social, identificacion_fiscal, pais_id,
                       direccion, ciudad, provincia_estado, codigo_postal,
                       telefono, email, persona_contacto, estado)
VALUES
    ('empresa', 'Cliente Demo S.A.', 'A11111111', 1,
     'Avenida Demo 45', 'Barcelona', 'Barcelona', '08001',
     '+34 900 111 222', 'compras@clientedemo.test', 'Juan Pérez', 'activo');

-- ----------------------------------------------------------------------------
-- PARTE 2 - Ejecutar contra la base de control: simplefactura_control
-- ----------------------------------------------------------------------------
-- USE simplefactura_control;
--
-- INSERT INTO tenants
--     (identificador, nombre_empresa, pais_id, plan_id,
--      db_host, db_name, db_usuario, db_password,
--      estado, email_contacto)
-- VALUES
--     ('cliente_pruebas', 'Empresa de Pruebas S.L.', 1, NULL,
--      '127.0.0.1', 'sf_cliente_pruebas', 'sf_cliente_pruebas_user', 'CAMBIAR_ESTA_CLAVE',
--      'prueba', 'admin@empresapruebas.test');
