#!/usr/bin/env bash
set -euo pipefail

# Bootstrap : clone le repo et lance le vrai installateur.
# Utilisation depuis l'ISO NixOS Minimal :

REPO="https://github.com/SunSinD/Projet-DO2-NixOS.git"
WORK="/tmp/do2config"

echo "DO2 - telechargement du dernier installateur..."
rm -rf "$WORK"
git clone "$REPO" "$WORK"
exec bash "$WORK/scripts/do2-install.sh"
