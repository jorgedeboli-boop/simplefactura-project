#!/usr/bin/env bash
# Flutter web + API PHP local (desarrollo sin FTP).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_DIR="$ROOT/flutter_app"
PUERTO="${SF_API_PORT:-8080}"
API_URL="http://localhost:${PUERTO}/index.php"

cleanup() {
  if [ -n "${API_PID:-}" ] && kill -0 "$API_PID" 2>/dev/null; then
    kill "$API_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

bash "$ROOT/scripts/serve_api.sh" &
API_PID=$!

echo "==> Esperando API..."
sleep 1
for _ in $(seq 1 25); do
  if curl -s "http://localhost:${PUERTO}/index.php" >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done

echo "==> Flutter web (API: $API_URL)"
cd "$FLUTTER_DIR"
flutter pub get
flutter run -d chrome --dart-define="API_BASE_URL=$API_URL"
