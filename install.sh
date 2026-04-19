#!/usr/bin/env bash
set -euo pipefail

# Bootstrap léger : télécharge toujours le vrai installateur depuis main.
# Utilisation depuis l'ISO NixOS Minimal :
#   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/SunSinD/Projet-DO2-Nixbook/main/install.sh)"

BASE="https://raw.githubusercontent.com/SunSinD/Projet-DO2-Nixbook/main"
TMP_INSTALL="$(mktemp)"
cleanup_tmp() { rm -f "$TMP_INSTALL" 2>/dev/null || true; }
trap cleanup_tmp EXIT

echo "DO2 - telechargement du dernier installateur..."
curl -fsSL "${BASE}/do2-install.sh" -o "$TMP_INSTALL"
exec bash "$TMP_INSTALL"
