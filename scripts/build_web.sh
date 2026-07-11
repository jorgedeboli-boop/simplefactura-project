#!/usr/bin/env bash
# Compila Flutter web y empaqueta la API PHP en build/web/api/
# (sin constantes.php: ese archivo solo vive en el servidor FTP)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_DIR="$ROOT/flutter_app"
API_DIR="$FLUTTER_DIR/build/web/api"

echo "==> Flutter pub get"
cd "$FLUTTER_DIR"
flutter pub get

echo "==> Flutter build web"
flutter build web

echo "==> Empaquetar API PHP"
mkdir -p "$API_DIR/endpoints" "$API_DIR/lib" "$API_DIR/config"

cp "$ROOT/backend/index.php" "$API_DIR/"
if [ -f "$ROOT/backend/.htaccess" ]; then
  cp "$ROOT/backend/.htaccess" "$API_DIR/"
fi

cp "$ROOT/backend/config/db.php" "$API_DIR/config/"
cp "$ROOT/backend/config/constantes.php.example" "$API_DIR/config/"

cp "$ROOT/backend/lib/"*.php "$API_DIR/lib/"
cp "$ROOT/backend/endpoints/"*.php "$API_DIR/endpoints/"

mkdir -p "$API_DIR/plantillas_factura" "$API_DIR/uploads"
cp "$ROOT/backend/plantillas_factura/"*.html "$API_DIR/plantillas_factura/" 2>/dev/null || true
if [ -f "$ROOT/backend/uploads/.htaccess" ]; then
  cp "$ROOT/backend/uploads/.htaccess" "$API_DIR/uploads/"
fi
touch "$API_DIR/uploads/.gitkeep"

echo "==> Build completada: $FLUTTER_DIR/build/web/"
echo "    (api/config/constantes.php NO incluido — conservar el del servidor)"
