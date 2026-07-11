#!/usr/bin/env bash
# Copia los archivos Flutter que deben estar siempre sincronizados con el build.
set -euo pipefail

ORIGEN="${1:?Ruta build/web}"
DESTINO="${2:?Carpeta destino}"

mkdir -p "$DESTINO"

for archivo in main.dart.js flutter_service_worker.js index.html version.json flutter_bootstrap.js; do
  if [ -f "$ORIGEN/$archivo" ]; then
    cp "$ORIGEN/$archivo" "$DESTINO/"
  fi
done

echo "Archivos críticos preparados en $DESTINO:"
ls -lh "$DESTINO"
