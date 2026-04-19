#!/usr/bin/env bash
set -euo pipefail
W=/tmp/do2config
echo "DO2 - telechargement du dernier installateur..."
rm -rf "$W"
git clone https://github.com/SunSinD/Projet-DO2-NixOS.git "$W"
exec bash "$W/do2-install.sh"
