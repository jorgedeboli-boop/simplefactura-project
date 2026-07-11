-- Personalizacion de factura en tenants existentes.
ALTER TABLE empresa_configuracion
    ADD COLUMN logotipo_file VARCHAR(128) NULL COMMENT 'Nombre de archivo del logo subido por el tenant'
        AFTER logotipo_url,
    ADD COLUMN factura_design TINYINT NOT NULL DEFAULT 1 COMMENT 'Numero de plantilla de factura (1-3)'
        AFTER color_primario,
    ADD COLUMN color_design VARCHAR(64) NOT NULL DEFAULT '#398bf7' COMMENT 'Color principal de la factura'
        AFTER factura_design;
