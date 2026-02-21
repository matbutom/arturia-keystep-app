#!/bin/bash
# Lanzador de Pétalo — copia el .app a /tmp para evitar el bloqueo de Gatekeeper
# en volúmenes externos, luego lo abre.
#
# Uso: ./launch.sh [build]
#   build = reconstruir antes de lanzar (opcional)

cd "$(dirname "$0")"

if [[ "$1" == "build" ]]; then
  echo "Compilando Pétalo..."
  flutter build macos --debug
fi

APP_SRC="build/macos/Build/Products/Debug/petalo_synth.app"
APP_DST="/tmp/petalo_synth.app"

if [[ ! -d "$APP_SRC" ]]; then
  echo "App no encontrada. Ejecuta: flutter build macos --debug"
  exit 1
fi

echo "Copiando app a /tmp..."
rm -rf "$APP_DST"
cp -R "$APP_SRC" "$APP_DST"
xattr -cr "$APP_DST"

echo "Abriendo Pétalo..."
open "$APP_DST"
