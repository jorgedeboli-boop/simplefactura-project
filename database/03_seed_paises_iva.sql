-- ============================================================================
-- Simple Factura - Datos semilla comunes (paises, IVA, roles, permisos)
-- Ejecutar contra la BD del tenant DESPUES de 02_tenant_schema.sql
-- Los IDs de pais son fijos en todo el sistema (control y todos los tenants).
--
-- Tasas de IVA/IGV/ITBMS verificadas para 2026:
--   España 21/10/4 % | Mexico 16 % (8 % frontera hasta 31/12/2026) | Costa Rica 13 %
--   Panama (ITBMS) 7 % | Guatemala 12 % | Colombia 19/5 % | Chile 19 %
--   Peru (IGV) 18 % | Ecuador 15 %
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Paises (IDs fijos: usalos igual en la BD de control)
-- ----------------------------------------------------------------------------
INSERT INTO paises (id, codigo_iso2, nombre, moneda_codigo, moneda_nombre, moneda_simbolo) VALUES
(1, 'ES', 'España',      'EUR', 'Euro',                  '€'),
(2, 'MX', 'México',      'MXN', 'Peso mexicano',         '$'),
(3, 'CR', 'Costa Rica',  'CRC', 'Colón costarricense',   '₡'),
(4, 'PA', 'Panamá',      'USD', 'Dólar estadounidense',  '$'),
(5, 'GT', 'Guatemala',   'GTQ', 'Quetzal',                'Q'),
(6, 'CO', 'Colombia',    'COP', 'Peso colombiano',        '$'),
(7, 'CL', 'Chile',       'CLP', 'Peso chileno',           '$'),
(8, 'PE', 'Perú',        'PEN', 'Sol',                    'S/'),
(9, 'EC', 'Ecuador',     'USD', 'Dólar estadounidense',  '$');

-- ----------------------------------------------------------------------------
-- Tipos de IVA / IGV / ITBMS por pais
-- ----------------------------------------------------------------------------
-- España (IVA)
INSERT INTO iva_tipos (pais_id, nombre, porcentaje, es_default) VALUES
(1, 'General',        21.00, 'true'),
(1, 'Reducido',       10.00, 'false'),
(1, 'Superreducido',   4.00, 'false'),
(1, 'Exento',          0.00, 'false');

-- Mexico (IVA)
INSERT INTO iva_tipos (pais_id, nombre, porcentaje, es_default) VALUES
(2, 'General',        16.00, 'true'),
(2, 'Frontera',        8.00, 'false'),
(2, 'Tasa 0%',         0.00, 'false');

-- Costa Rica (IVA)
INSERT INTO iva_tipos (pais_id, nombre, porcentaje, es_default) VALUES
(3, 'General',        13.00, 'true'),
(3, 'Reducido 4%',     4.00, 'false'),
(3, 'Reducido 2%',     2.00, 'false'),
(3, 'Reducido 1%',     1.00, 'false'),
(3, 'Exento',          0.00, 'false');

-- Panama (ITBMS)
INSERT INTO iva_tipos (pais_id, nombre, porcentaje, es_default) VALUES
(4, 'General (ITBMS)', 7.00, 'true'),
(4, 'Alcohol / Hospedaje', 10.00, 'false'),
(4, 'Tabaco',          15.00, 'false'),
(4, 'Exento',           0.00, 'false');

-- Guatemala (IVA)
INSERT INTO iva_tipos (pais_id, nombre, porcentaje, es_default) VALUES
(5, 'General',        12.00, 'true'),
(5, 'Exento',          0.00, 'false');

-- Colombia (IVA)
INSERT INTO iva_tipos (pais_id, nombre, porcentaje, es_default) VALUES
(6, 'General',        19.00, 'true'),
(6, 'Reducido',        5.00, 'false'),
(6, 'Exento',          0.00, 'false');

-- Chile (IVA)
INSERT INTO iva_tipos (pais_id, nombre, porcentaje, es_default) VALUES
(7, 'General',        19.00, 'true'),
(7, 'Exento',          0.00, 'false');

-- Peru (IGV)
INSERT INTO iva_tipos (pais_id, nombre, porcentaje, es_default) VALUES
(8, 'General (IGV)',  18.00, 'true'),
(8, 'Exonerado',       0.00, 'false');

-- Ecuador (IVA)
INSERT INTO iva_tipos (pais_id, nombre, porcentaje, es_default) VALUES
(9, 'General',        15.00, 'true'),
(9, 'Tarifa 0%',       0.00, 'false');

-- ----------------------------------------------------------------------------
-- Roles base (jerarquia de usuarios)
-- ----------------------------------------------------------------------------
INSERT INTO roles (id, nombre, nivel, descripcion) VALUES
(1, 'Administrador', 1, 'Acceso total: usuarios, configuracion, facturacion'),
(2, 'Gestor',        2, 'Gestiona clientes, proveedores, presupuestos y facturas'),
(3, 'Comercial',     3, 'Crea presupuestos y facturas, sin acceso a configuracion'),
(4, 'Solo lectura',  4, 'Puede consultar pero no crear ni modificar');

-- ----------------------------------------------------------------------------
-- Permisos
-- ----------------------------------------------------------------------------
INSERT INTO permisos (id, codigo, descripcion) VALUES
(1,  'usuarios.ver',                 'Ver usuarios'),
(2,  'usuarios.crear',               'Crear usuarios'),
(3,  'usuarios.editar',              'Editar usuarios'),
(4,  'usuarios.eliminar',            'Eliminar usuarios'),
(5,  'empresa.ver',                  'Ver configuracion de empresa'),
(6,  'empresa.editar',               'Editar configuracion de empresa'),
(7,  'clientes.ver',                 'Ver clientes'),
(8,  'clientes.crear',               'Crear clientes'),
(9,  'clientes.editar',              'Editar clientes'),
(10, 'clientes.eliminar',            'Eliminar clientes'),
(11, 'proveedores.ver',              'Ver proveedores'),
(12, 'proveedores.crear',            'Crear proveedores'),
(13, 'proveedores.editar',           'Editar proveedores'),
(14, 'proveedores.eliminar',         'Eliminar proveedores'),
(15, 'presupuestos.ver',             'Ver presupuestos'),
(16, 'presupuestos.crear',           'Crear presupuestos'),
(17, 'presupuestos.editar',          'Editar presupuestos'),
(18, 'presupuestos.eliminar',        'Eliminar presupuestos'),
(19, 'facturas.ver',                 'Ver facturas'),
(20, 'facturas.crear',               'Crear facturas'),
(21, 'facturas.editar',              'Editar facturas'),
(22, 'facturas.anular',              'Anular facturas'),
(23, 'facturas_rectificativas.crear','Crear facturas rectificativas');

-- ----------------------------------------------------------------------------
-- Asignacion de permisos por rol
-- ----------------------------------------------------------------------------
-- Administrador: todos los permisos
INSERT INTO roles_permisos (role_id, permiso_id) SELECT 1, id FROM permisos;

-- Gestor: todo menos gestion de usuarios
INSERT INTO roles_permisos (role_id, permiso_id) SELECT 2, id FROM permisos WHERE codigo NOT LIKE 'usuarios.%';

-- Comercial: clientes, presupuestos, y ver/crear facturas (sin anular ni rectificar)
INSERT INTO roles_permisos (role_id, permiso_id)
SELECT 3, id FROM permisos
WHERE codigo IN ('clientes.ver','clientes.crear','clientes.editar',
                  'presupuestos.ver','presupuestos.crear','presupuestos.editar',
                  'facturas.ver','facturas.crear','empresa.ver');

-- Solo lectura: todos los .ver
INSERT INTO roles_permisos (role_id, permiso_id) SELECT 4, id FROM permisos WHERE codigo LIKE '%.ver';

-- ----------------------------------------------------------------------------
-- Series de numeracion inicial para el ano en curso
-- ----------------------------------------------------------------------------
INSERT INTO series_numeracion (tipo_documento, serie, anio, ultimo_numero) VALUES
('presupuesto',           'A', YEAR(CURDATE()), 0),
('factura',               'A', YEAR(CURDATE()), 0),
('factura_simplificada',  'A', YEAR(CURDATE()), 0),
('factura_rectificativa', 'A', YEAR(CURDATE()), 0);
