-- Añade tipo_empresa a tenants existentes (ejecutar contra la BD del tenant).
ALTER TABLE empresa_configuracion
    ADD COLUMN tipo_empresa ENUM('autonomo','sl','slu') NOT NULL DEFAULT 'sl'
    AFTER identificacion_fiscal;
