#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE_ID=$(bash "$ROOT/scripts/ios_simulator_device.sh")

cd "$ROOT/flutter_app"
exec flutter run -d "$DEVICE_ID" \
  --dart-define=API_BASE_URL=http://localhost:8080/index.php \
  "$@"
