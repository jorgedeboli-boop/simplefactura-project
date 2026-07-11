#!/usr/bin/env bash
# Arranca el simulador iOS y devuelve el ID del primer iPhone disponible.
set -euo pipefail

open -a Simulator 2>/dev/null || flutter emulators --launch apple_ios_simulator

DEVICE_ID=""
for _ in $(seq 1 60); do
  DEVICE_ID=$(flutter devices --machine 2>/dev/null | python3 -c "
import sys, json
devices = json.load(sys.stdin)
for d in devices:
    if d.get('targetPlatform') == 'ios' and d.get('emulator'):
        print(d['id'])
        break
" 2>/dev/null || true)
  if [ -n "$DEVICE_ID" ]; then
    echo "$DEVICE_ID"
    exit 0
  fi
  sleep 0.5
done

echo "No se encontró simulador iOS encendido." >&2
exit 1
