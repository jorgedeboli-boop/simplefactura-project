-- Tokens de recuperacion de contraseña (base de control).
-- Ejecutar en simplefactura_control si la tabla aun no existe.

USE simplefactura_control;

CREATE TABLE IF NOT EXISTS tokens_recuperacion_password (
    id                  INT NOT NULL AUTO_INCREMENT,
    token               CHAR(64) NOT NULL,
    tenant_id           INT NOT NULL,
    usuario_id          INT NOT NULL COMMENT 'id en la tabla usuarios del tenant',
    email               VARCHAR(150) NOT NULL,
    fecha_creacion      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion    DATETIME NOT NULL,
    usado               ENUM('false','true') NOT NULL DEFAULT 'false',
    PRIMARY KEY (id),
    UNIQUE KEY uq_token (token),
    KEY idx_email (email),
    KEY idx_expiracion (fecha_expiracion),
    CONSTRAINT fk_recuperacion_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
