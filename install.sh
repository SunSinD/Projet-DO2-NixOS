#!/usr/bin/env bash
set -euo pipefail

# Thin bootstrap: always downloads the real installer from main.
# If you still see "Enter disk name (nvme0n1…)", you are NOT running this file —
# use this exact command from the live ISO:
#   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/SunSinD/Projet-DO2-NixOS/main/install.sh)"

BASE="https://raw.githubusercontent.com/SunSinD/Projet-DO2-NixOS/main"
TMP_INSTALL="$(mktemp)"
cleanup_tmp() { rm -f "$TMP_INSTALL" 2>/dev/null || true; }
trap cleanup_tmp EXIT

echo "DO2 — fetching latest installer (numeric disk menu: 0, 1, …)…"
curl -fsSL "${BASE}/do2-install.sh" -o "$TMP_INSTALL"
exec bash "$TMP_INSTALL"
