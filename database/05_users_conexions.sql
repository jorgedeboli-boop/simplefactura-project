-- Tabla de auditoria de conexiones de usuario (por tenant).
-- Ejecutar en la BD de cada tenant si aun no existe.

CREATE TABLE IF NOT EXISTS usersConexions (
    idUserConexion           INT NOT NULL AUTO_INCREMENT,
    userId                   INT NOT NULL,
    locationLong             VARCHAR(128) NOT NULL DEFAULT '0',
    locationLat              VARCHAR(128) NOT NULL DEFAULT '0',
    dateConexion             DATETIME NOT NULL,
    groupId                  INT NOT NULL,
    logTxt                   TEXT NOT NULL,
    sucursalIdUserConexion   INT NOT NULL DEFAULT 0,
    companyIdUserConexion    INT NOT NULL DEFAULT 0,
    ipNumberUser             VARCHAR(128) NOT NULL DEFAULT '',
    userAgent                VARCHAR(256) NOT NULL DEFAULT '',
    tokensessioncontrol      VARCHAR(128) NOT NULL DEFAULT '',
    state_connection         ENUM('false','true') NOT NULL DEFAULT 'false',
    PRIMARY KEY (idUserConexion),
    KEY idx_user (userId),
    KEY idx_group (groupId),
    KEY idx_date (dateConexion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
