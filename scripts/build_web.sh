#!/usr/bin/env bash
# Compila Flutter web y empaqueta la API PHP en build/web/api/
# (sin constantes.php: ese archivo solo vive en el servidor FTP)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_DIR="$ROOT/flutter_app"
API_DIR="$FLUTTER_DIR/build/web/api"
WEB_OUT="$FLUTTER_DIR/build/web"

echo "==> Flutter pub get"
cd "$FLUTTER_DIR"
flutter pub get

echo "==> Flutter build web (CDN CanvasKit + optimización -O4)"
# --web-resources-cdn: CanvasKit (~7MB) se descarga de Google CDN (más rápido y cacheable)
# -O4: máxima optimización del JS
# --no-wasm-dry-run: evita trabajo extra en el build
flutter build web \
  --release \
  --web-resources-cdn \
  --no-wasm-dry-run \
  -O4

echo "==> .htaccess (gzip + caché)"
cp "$FLUTTER_DIR/web/.htaccess" "$WEB_OUT/.htaccess"

echo "==> Precomprimir JS/WASM con gzip (si el hosting lo sirve)"
if command -v gzip >/dev/null 2>&1; then
  # Solo archivos grandes; no tocar flutter_service_worker.js
  for f in "$WEB_OUT"/main.dart.js "$WEB_OUT"/flutter.js "$WEB_OUT"/flutter_bootstrap.js "$WEB_OUT"/main.dart.js_*.part.js; do
    if [ -f "$f" ]; then
      gzip -9 -k -f "$f"
    fi
  done
  # CanvasKit local (por si el CDN falla o no se usa)
  if [ -d "$WEB_OUT/canvaskit" ]; then
    find "$WEB_OUT/canvaskit" \( -name '*.js' -o -name '*.wasm' \) -type f -print0 \
      | xargs -0 -I{} gzip -9 -k -f "{}" 2>/dev/null || true
  fi
fi

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

echo "==> Tamaños"
ls -lh "$WEB_OUT/main.dart.js" "$WEB_OUT/main.dart.js.gz" 2>/dev/null || ls -lh "$WEB_OUT/main.dart.js"
du -sh "$WEB_OUT" "$WEB_OUT/canvaskit" 2>/dev/null || du -sh "$WEB_OUT"

echo "==> Build completada: $WEB_OUT/"
echo "    (api/config/constantes.php NO incluido — conservar el del servidor)"
