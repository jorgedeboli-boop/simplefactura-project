-- Personalizacion de factura en tenants existentes (idempotente).
-- Ejecutar contra la BD del tenant en produccion (phpMyAdmin).

SET @db = DATABASE();

SET @existe = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'empresa_configuracion' AND COLUMN_NAME = 'logotipo_file');
SET @sql = IF(@existe = 0,
    'ALTER TABLE empresa_configuracion ADD COLUMN logotipo_file VARCHAR(128) NULL COMMENT ''Nombre de archivo del logo subido por el tenant'' AFTER logotipo_url',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @existe = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'empresa_configuracion' AND COLUMN_NAME = 'factura_design');
SET @sql = IF(@existe = 0,
    'ALTER TABLE empresa_configuracion ADD COLUMN factura_design TINYINT NOT NULL DEFAULT 1 COMMENT ''Numero de plantilla de factura (1-3)'' AFTER color_primario',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @existe = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'empresa_configuracion' AND COLUMN_NAME = 'color_design');
SET @sql = IF(@existe = 0,
    'ALTER TABLE empresa_configuracion ADD COLUMN color_design VARCHAR(64) NOT NULL DEFAULT ''#398bf7'' COMMENT ''Color principal de la factura'' AFTER factura_design',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
