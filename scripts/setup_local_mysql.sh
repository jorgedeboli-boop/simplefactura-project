#!/usr/bin/env bash
# Crea usuario MySQL local, bases de datos y datos de prueba para desarrollo.
# Requiere acceso root a MySQL (Homebrew: mysql -u root -p).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DB_DIR="$ROOT/database"
CONSTANTES="$ROOT/backend/config/constantes.php"
APP_USER="${SF_DB_USER:-simplefactura_app}"
APP_PASS="${SF_DB_PASS:-}"
TENANT_DB="${SF_TENANT_DB:-sf_cliente_pruebas}"

if ! command -v mysql >/dev/null 2>&1; then
  echo "❌ MySQL no encontrado. Instálalo: brew install mysql && brew services start mysql"
  exit 1
fi

if [ -z "$APP_PASS" ]; then
  read -rsp "Contraseña para el usuario MySQL '$APP_USER': " APP_PASS
  echo ""
fi

read -rsp "Contraseña de MySQL root: " ROOT_PASS
echo ""

mysql_root() {
  mysql -u root -p"$ROOT_PASS" "$@"
}

echo "==> Creando usuario y bases de datos..."
mysql_root <<SQL
CREATE DATABASE IF NOT EXISTS simplefactura_control
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS ${TENANT_DB}
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${APP_USER}'@'localhost' IDENTIFIED BY '${APP_PASS}';
CREATE USER IF NOT EXISTS '${APP_USER}'@'127.0.0.1' IDENTIFIED BY '${APP_PASS}';

GRANT ALL PRIVILEGES ON simplefactura_control.* TO '${APP_USER}'@'localhost';
GRANT ALL PRIVILEGES ON simplefactura_control.* TO '${APP_USER}'@'127.0.0.1';
GRANT ALL PRIVILEGES ON ${TENANT_DB}.* TO '${APP_USER}'@'localhost';
GRANT ALL PRIVILEGES ON ${TENANT_DB}.* TO '${APP_USER}'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL

echo "==> Importando esquemas..."
mysql_root simplefactura_control < "$DB_DIR/01_control_schema.sql"

mysql_root simplefactura_control <<'SQL'
INSERT IGNORE INTO paises (id, codigo_iso2, nombre, moneda_codigo, moneda_nombre, moneda_simbolo) VALUES
(1, 'ES', 'España', 'EUR', 'Euro', '€');
SQL

sed "s/{DB_NAME}/${TENANT_DB}/g" "$DB_DIR/02_tenant_schema.sql" | mysql_root
mysql_root "$TENANT_DB" < "$DB_DIR/03_seed_paises_iva.sql"
mysql_root "$TENANT_DB" < "$DB_DIR/04_password_reset_tokens.sql" 2>/dev/null || true
mysql_root "$TENANT_DB" < "$DB_DIR/05_users_conexions.sql" 2>/dev/null || true
mysql_root "$TENANT_DB" < "$DB_DIR/04_seed_cliente_pruebas.sql"
mysql_root "$TENANT_DB" < "$DB_DIR/06_empresa_tipo_empresa.sql" 2>/dev/null || true

mysql_root simplefactura_control <<SQL
INSERT INTO tenants
    (identificador, nombre_empresa, pais_id, plan_id,
     db_host, db_name, db_usuario, db_password,
     estado, email_contacto)
VALUES
    ('cliente_pruebas', 'Empresa de Pruebas S.L.', 1, NULL,
     '127.0.0.1', '${TENANT_DB}', '${APP_USER}', '${APP_PASS}',
     'prueba', 'admin@empresapruebas.test')
ON DUPLICATE KEY UPDATE
    db_usuario = VALUES(db_usuario),
    db_password = VALUES(db_password),
    estado = 'prueba';
SQL

if [ ! -f "$CONSTANTES" ]; then
  cp "$ROOT/backend/config/constantes.php.example" "$CONSTANTES"
fi

CONSTANTES_FILE="$CONSTANTES" APP_PASS="$APP_PASS" php <<'PHP'
<?php
$f = getenv('CONSTANTES_FILE');
$pass = getenv('APP_PASS');
$c = file_get_contents($f);
$c = preg_replace(
    "/define\('SF_CONTROL_DB_PASS', '[^']*'\);/",
    "define('SF_CONTROL_DB_PASS', " . var_export($pass, true) . ");",
    $c
);
$c = preg_replace(
    "/define\('SF_DEBUG', false\);/",
    "define('SF_DEBUG', true);",
    $c
);
file_put_contents($f, $c);
PHP

echo ""
echo "✅ MySQL local listo."
echo "   Usuario: $APP_USER"
echo "   Bases: simplefactura_control, $TENANT_DB"
echo "   Login de prueba: admin@empresapruebas.test / Prueba1234!"
echo ""
echo "   Arranca la API: bash scripts/serve_api.sh"
echo "   Luego lanza Flutter iOS desde VS Code/Cursor."
