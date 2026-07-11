#!/usr/bin/env bash
# Servidor PHP local para desarrollo (sin FTP).
# URL: http://localhost:8080/index.php?accion=auth_login
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND="$ROOT/backend"
CONSTANTES="$BACKEND/config/constantes.php"
PUERTO="${SF_API_PORT:-8080}"

if ! command -v php >/dev/null 2>&1; then
  echo "❌ PHP no encontrado. Instálalo (brew install php) y vuelve a intentar."
  exit 1
fi

if [ ! -f "$CONSTANTES" ]; then
  cp "$BACKEND/config/constantes.php.example" "$CONSTANTES"
  echo "⚠️  Creado $CONSTANTES desde la plantilla."
  echo "   Edítalo con tus credenciales MySQL locales antes de continuar."
  echo ""
fi

echo "==> API local en http://localhost:${PUERTO}/index.php"
echo "    Ctrl+C para detener"
echo ""

cd "$BACKEND"
exec php -S "localhost:${PUERTO}" -t .
