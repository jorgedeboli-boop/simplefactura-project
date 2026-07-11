-- ============================================================================
-- Simple Factura - Base de datos de TENANT (plantilla por cliente)
-- Motor: MariaDB 10.1  |  Compatible: sin JSON nativo, sin CTE, sin window functions
--
-- Este script se ejecuta UNA VEZ por cada cliente nuevo, contra su propia
-- base de datos vacia (ej: sf_cliente_pruebas). Sustituye {DB_NAME} por el
-- nombre real antes de ejecutar, o usa el script de aprovisionamiento.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS {DB_NAME}
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE {DB_NAME};

-- ----------------------------------------------------------------------------
-- Catalogo de paises (copia local del catalogo de control, self-contained)
-- ----------------------------------------------------------------------------
CREATE TABLE paises (
    id              INT NOT NULL AUTO_INCREMENT,
    codigo_iso2     CHAR(2) NOT NULL,
    nombre          VARCHAR(64) NOT NULL,
    moneda_codigo   CHAR(3) NOT NULL,
    moneda_nombre   VARCHAR(64) NOT NULL,
    moneda_simbolo  VARCHAR(8) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_codigo_iso2 (codigo_iso2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Tipos de IVA / IGV / ITBMS por pais (regimen de impuestos)
-- ----------------------------------------------------------------------------
CREATE TABLE iva_tipos (
    id              INT NOT NULL AUTO_INCREMENT,
    pais_id         INT NOT NULL,
    nombre          VARCHAR(64) NOT NULL COMMENT 'Ej: General, Reducido, Exento',
    porcentaje      DECIMAL(5,2) NOT NULL,
    es_default      ENUM('false','true') NOT NULL DEFAULT 'false',
    PRIMARY KEY (id),
    KEY idx_pais (pais_id),
    CONSTRAINT fk_iva_pais FOREIGN KEY (pais_id) REFERENCES paises(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Configuracion de la empresa (fila unica - el negocio dueno de este tenant)
-- ----------------------------------------------------------------------------
CREATE TABLE empresa_configuracion (
    id                      INT NOT NULL AUTO_INCREMENT,
    razon_social            VARCHAR(255) NOT NULL,
    nombre_comercial        VARCHAR(255) NULL,
    identificacion_fiscal   VARCHAR(64) NOT NULL COMMENT 'NIF/RFC/RUC/RUT/NIT segun pais',
    pais_id                 INT NOT NULL,
    direccion               VARCHAR(255) NULL,
    ciudad                  VARCHAR(100) NULL,
    provincia_estado        VARCHAR(100) NULL,
    codigo_postal           VARCHAR(20) NULL,
    telefono_principal      VARCHAR(30) NULL,
    telefono_secundario     VARCHAR(30) NULL,
    email_corporativo       VARCHAR(150) NULL,
    email_facturacion       VARCHAR(150) NULL,
    sitio_web               VARCHAR(150) NULL,
    moneda_codigo           CHAR(3) NOT NULL,
    regimen_iva_id          INT NULL COMMENT 'tipo de IVA por defecto para esta empresa',
    logotipo_url            VARCHAR(255) NULL,
    color_primario          CHAR(7) NOT NULL DEFAULT '#398bf7',
    iban_cuenta             VARCHAR(64) NULL,
    fecha_creacion          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_empresa_pais FOREIGN KEY (pais_id) REFERENCES paises(id),
    CONSTRAINT fk_empresa_iva FOREIGN KEY (regimen_iva_id) REFERENCES iva_tipos(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Roles (jerarquia de usuarios) y permisos
-- ----------------------------------------------------------------------------
CREATE TABLE roles (
    id              INT NOT NULL AUTO_INCREMENT,
    nombre          VARCHAR(64) NOT NULL,
    nivel           INT NOT NULL DEFAULT 99 COMMENT 'menor numero = mayor jerarquia',
    descripcion     VARCHAR(255) NULL,
    fecha_creacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE permisos (
    id              INT NOT NULL AUTO_INCREMENT,
    codigo          VARCHAR(64) NOT NULL COMMENT 'ej: clientes.crear, facturas.anular',
    descripcion     VARCHAR(255) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_codigo (codigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE roles_permisos (
    role_id     INT NOT NULL,
    permiso_id  INT NOT NULL,
    PRIMARY KEY (role_id, permiso_id),
    CONSTRAINT fk_rp_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    CONSTRAINT fk_rp_permiso FOREIGN KEY (permiso_id) REFERENCES permisos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Usuarios del sistema (empleados del negocio que usan Simple Factura)
-- ----------------------------------------------------------------------------
CREATE TABLE usuarios (
    id              INT NOT NULL AUTO_INCREMENT,
    nombre          VARCHAR(100) NOT NULL,
    apellidos       VARCHAR(150) NULL,
    email           VARCHAR(150) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    telefono        VARCHAR(30) NULL,
    role_id         INT NOT NULL,
    estado          ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
    ultimo_acceso   DATETIME NULL,
    fecha_creacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_email (email),
    CONSTRAINT fk_usuarios_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- NOTA: los tokens de sesion NO se guardan aqui. Se guardan centralizados en
-- simplefactura_control.tokens_globales, que es quien enruta cada peticion
-- de la app hacia esta base de datos. Ver 01_control_schema.sql.

-- ----------------------------------------------------------------------------
-- Clientes (a quienes se les factura)
-- ----------------------------------------------------------------------------
CREATE TABLE clientes (
    id                      INT NOT NULL AUTO_INCREMENT,
    tipo                    ENUM('particular','empresa') NOT NULL DEFAULT 'empresa',
    nombre_razon_social     VARCHAR(255) NOT NULL,
    identificacion_fiscal   VARCHAR(64) NULL,
    pais_id                 INT NOT NULL,
    direccion               VARCHAR(255) NULL,
    ciudad                  VARCHAR(100) NULL,
    provincia_estado        VARCHAR(100) NULL,
    codigo_postal           VARCHAR(20) NULL,
    telefono                VARCHAR(30) NULL,
    email                   VARCHAR(150) NULL,
    persona_contacto        VARCHAR(150) NULL,
    notas                   TEXT NULL,
    estado                  ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
    fecha_creacion          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_estado (estado),
    CONSTRAINT fk_clientes_pais FOREIGN KEY (pais_id) REFERENCES paises(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Proveedores
-- ----------------------------------------------------------------------------
CREATE TABLE proveedores (
    id                      INT NOT NULL AUTO_INCREMENT,
    tipo                    ENUM('particular','empresa') NOT NULL DEFAULT 'empresa',
    nombre_razon_social     VARCHAR(255) NOT NULL,
    identificacion_fiscal   VARCHAR(64) NULL,
    pais_id                 INT NOT NULL,
    direccion               VARCHAR(255) NULL,
    ciudad                  VARCHAR(100) NULL,
    provincia_estado        VARCHAR(100) NULL,
    codigo_postal           VARCHAR(20) NULL,
    telefono                VARCHAR(30) NULL,
    email                   VARCHAR(150) NULL,
    persona_contacto        VARCHAR(150) NULL,
    notas                   TEXT NULL,
    estado                  ENUM('activo','inactivo') NOT NULL DEFAULT 'activo',
    fecha_creacion          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_estado (estado),
    CONSTRAINT fk_proveedores_pais FOREIGN KEY (pais_id) REFERENCES paises(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Series de numeracion (correlativo legal, sin huecos, por tipo/serie/anio)
-- ----------------------------------------------------------------------------
CREATE TABLE series_numeracion (
    id              INT NOT NULL AUTO_INCREMENT,
    tipo_documento  ENUM('presupuesto','factura','factura_simplificada','factura_rectificativa') NOT NULL,
    serie           VARCHAR(10) NOT NULL DEFAULT 'A',
    anio            INT NOT NULL,
    ultimo_numero   INT NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uq_serie (tipo_documento, serie, anio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Presupuestos
-- ----------------------------------------------------------------------------
CREATE TABLE presupuestos (
    id                  INT NOT NULL AUTO_INCREMENT,
    numero_presupuesto  VARCHAR(30) NOT NULL,
    cliente_id          INT NOT NULL,
    fecha_emision       DATE NOT NULL,
    fecha_validez       DATE NULL,
    estado              ENUM('borrador','enviado','aceptado','rechazado','facturado') NOT NULL DEFAULT 'borrador',
    subtotal            DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_iva           DECIMAL(15,2) NOT NULL DEFAULT 0,
    total               DECIMAL(15,2) NOT NULL DEFAULT 0,
    moneda_codigo       CHAR(3) NOT NULL,
    notas               TEXT NULL,
    usuario_id          INT NOT NULL,
    fecha_creacion      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_numero_presupuesto (numero_presupuesto),
    KEY idx_cliente (cliente_id),
    KEY idx_estado (estado),
    CONSTRAINT fk_presupuestos_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    CONSTRAINT fk_presupuestos_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE presupuestos_lineas (
    id                      INT NOT NULL AUTO_INCREMENT,
    presupuesto_id          INT NOT NULL,
    descripcion             VARCHAR(512) NOT NULL,
    cantidad                DECIMAL(10,2) NOT NULL DEFAULT 1,
    precio_unitario         DECIMAL(15,2) NOT NULL DEFAULT 0,
    descuento_porcentaje    DECIMAL(5,2) NOT NULL DEFAULT 0,
    iva_tipo_id             INT NOT NULL,
    importe_linea           DECIMAL(15,2) NOT NULL DEFAULT 0,
    orden                   INT NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    KEY idx_presupuesto (presupuesto_id),
    CONSTRAINT fk_pl_presupuesto FOREIGN KEY (presupuesto_id) REFERENCES presupuestos(id) ON DELETE CASCADE,
    CONSTRAINT fk_pl_iva FOREIGN KEY (iva_tipo_id) REFERENCES iva_tipos(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Facturas (normal / simplificada / rectificativa en una sola tabla)
-- ----------------------------------------------------------------------------
CREATE TABLE facturas (
    id                          INT NOT NULL AUTO_INCREMENT,
    tipo_factura                ENUM('normal','simplificada','rectificativa') NOT NULL DEFAULT 'normal',
    numero_factura              VARCHAR(30) NOT NULL,
    serie                       VARCHAR(10) NOT NULL DEFAULT 'A',
    factura_rectificada_id      INT NULL COMMENT 'solo si tipo_factura = rectificativa',
    motivo_rectificacion        VARCHAR(255) NULL,
    cliente_id                  INT NULL COMMENT 'nulo permitido en simplificadas sin datos completos',
    presupuesto_origen_id       INT NULL,
    fecha_emision               DATE NOT NULL,
    fecha_vencimiento           DATE NULL,
    estado                      ENUM('borrador','emitida','pagada','vencida','anulada') NOT NULL DEFAULT 'emitida',
    forma_pago                  VARCHAR(64) NULL,
    subtotal                    DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_iva                   DECIMAL(15,2) NOT NULL DEFAULT 0,
    total                       DECIMAL(15,2) NOT NULL DEFAULT 0,
    moneda_codigo                CHAR(3) NOT NULL,
    notas                       TEXT NULL,
    usuario_id                  INT NOT NULL,
    fecha_creacion               DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_serie_numero (serie, numero_factura),
    KEY idx_cliente (cliente_id),
    KEY idx_estado (estado),
    KEY idx_tipo (tipo_factura),
    CONSTRAINT fk_facturas_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    CONSTRAINT fk_facturas_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    CONSTRAINT fk_facturas_presupuesto FOREIGN KEY (presupuesto_origen_id) REFERENCES presupuestos(id),
    CONSTRAINT fk_facturas_rectificada FOREIGN KEY (factura_rectificada_id) REFERENCES facturas(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE facturas_lineas (
    id                      INT NOT NULL AUTO_INCREMENT,
    factura_id              INT NOT NULL,
    descripcion             VARCHAR(512) NOT NULL,
    cantidad                DECIMAL(10,2) NOT NULL DEFAULT 1,
    precio_unitario         DECIMAL(15,2) NOT NULL DEFAULT 0,
    descuento_porcentaje    DECIMAL(5,2) NOT NULL DEFAULT 0,
    iva_tipo_id             INT NOT NULL,
    importe_linea           DECIMAL(15,2) NOT NULL DEFAULT 0,
    orden                   INT NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    KEY idx_factura (factura_id),
    CONSTRAINT fk_fl_factura FOREIGN KEY (factura_id) REFERENCES facturas(id) ON DELETE CASCADE,
    CONSTRAINT fk_fl_iva FOREIGN KEY (iva_tipo_id) REFERENCES iva_tipos(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
