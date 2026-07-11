#!/usr/bin/env bash
# Arranca el simulador iOS y espera a que Flutter lo detecte.
set -euo pipefail

open -a Simulator 2>/dev/null || flutter emulators --launch apple_ios_simulator

for _ in $(seq 1 90); do
  if flutter devices --machine 2>/dev/null | python3 -c "
import sys, json
devices = json.load(sys.stdin)
print(any(d.get('targetPlatform')=='ios' and d.get('emulator') for d in devices))
" 2>/dev/null | grep -q True; then
    exit 0
  fi
  sleep 0.5
done

echo "El simulador iOS no respondió a tiempo." >&2
exit 1
