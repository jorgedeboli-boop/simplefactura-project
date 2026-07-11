-- ============================================================================
-- Simple Factura - Base de datos de CONTROL (master)
-- Motor: MariaDB 10.1  |  Compatible: sin JSON nativo, sin CTE, sin window functions
--
-- Esta base de datos NO contiene facturas ni datos de negocio de ningun
-- cliente. Solo administra qué tenants (clientes de Simple Factura) existen
-- y cómo conectar a la base de datos independiente de cada uno.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS simplefactura_control
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE simplefactura_control;

-- ----------------------------------------------------------------------------
-- Catalogo de paises soportados (id fijo, se replica tal cual en cada tenant)
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
-- Planes disponibles (para cuando exista la web de marketing / cobros)
-- ----------------------------------------------------------------------------
CREATE TABLE planes (
    id              INT NOT NULL AUTO_INCREMENT,
    codigo          VARCHAR(32) NOT NULL,
    nombre          VARCHAR(64) NOT NULL,
    max_usuarios    INT NOT NULL DEFAULT 1,
    precio_mensual  DECIMAL(10,2) NOT NULL DEFAULT 0,
    moneda_codigo   CHAR(3) NOT NULL DEFAULT 'USD',
    activo          ENUM('false','true') NOT NULL DEFAULT 'true',
    PRIMARY KEY (id),
    UNIQUE KEY uq_codigo (codigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Tenants: un registro por cada cliente de Simple Factura.
-- Cada tenant tiene su PROPIA base de datos independiente (aislamiento total).
-- ----------------------------------------------------------------------------
CREATE TABLE tenants (
    id                  INT NOT NULL AUTO_INCREMENT,
    identificador       VARCHAR(64) NOT NULL COMMENT 'slug unico, ej: cliente_pruebas',
    nombre_empresa      VARCHAR(255) NOT NULL,
    pais_id             INT NOT NULL,
    plan_id             INT NULL,
    db_host             VARCHAR(255) NOT NULL DEFAULT '127.0.0.1',
    db_name             VARCHAR(64) NOT NULL,
    db_usuario          VARCHAR(64) NOT NULL,
    db_password         VARCHAR(255) NOT NULL COMMENT 'idealmente cifrado a nivel de aplicacion',
    estado              ENUM('prueba','activo','suspendido','baja') NOT NULL DEFAULT 'prueba',
    email_contacto      VARCHAR(150) NOT NULL,
    fecha_alta          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_baja          DATETIME NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_identificador (identificador),
    UNIQUE KEY uq_db_name (db_name),
    KEY idx_estado (estado),
    CONSTRAINT fk_tenants_pais FOREIGN KEY (pais_id) REFERENCES paises(id),
    CONSTRAINT fk_tenants_plan FOREIGN KEY (plan_id) REFERENCES planes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Tokens globales: enrutan cada peticion autenticada a su tenant.
-- El cliente (app Flutter) solo envia el token; el backend lo busca aqui
-- para saber a que base de datos conectarse y que usuario (id dentro del
-- tenant) esta autenticado. No hay FK cruzada hacia usuarios del tenant
-- porque son bases de datos distintas; la integridad se valida en la app.
-- ----------------------------------------------------------------------------
CREATE TABLE tokens_globales (
    id                  INT NOT NULL AUTO_INCREMENT,
    token               CHAR(64) NOT NULL,
    tenant_id           INT NOT NULL,
    usuario_id          INT NOT NULL COMMENT 'id en la tabla usuarios del tenant',
    ip                  VARCHAR(45) NULL,
    user_agent          VARCHAR(255) NULL,
    fecha_creacion      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion    DATETIME NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_token (token),
    KEY idx_tenant (tenant_id),
    CONSTRAINT fk_tokens_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
