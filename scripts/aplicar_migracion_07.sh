#!/usr/bin/env bash
# Aplica la migracion 07 (personalizacion de factura) en la BD del tenant local.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TENANT_DB="${SF_TENANT_DB:-sf_cliente_pruebas}"

read -rsp "Contraseña MySQL root: " ROOT_PASS
echo ""

mysql -u root -p"$ROOT_PASS" "$TENANT_DB" < "$ROOT/database/07_empresa_factura_personalizacion.sql" 2>/dev/null || {
  echo "⚠️  Algunas columnas pueden existir ya. Comprueba manualmente:"
  mysql -u root -p"$ROOT_PASS" "$TENANT_DB" -e \
    "SHOW COLUMNS FROM empresa_configuracion LIKE 'factura_design';
     SHOW COLUMNS FROM empresa_configuracion LIKE 'color_design';
     SHOW COLUMNS FROM empresa_configuracion LIKE 'logotipo_file';"
}

echo "✅ Migracion 07 aplicada (o ya existente) en $TENANT_DB"
