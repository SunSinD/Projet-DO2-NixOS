#!/usr/bin/env bash
set -euo pipefail

MARKER="$HOME/.do2-welcome-shown"
[ -f "$MARKER" ] && exit 0
touch "$MARKER"

command -v yad >/dev/null 2>&1 || exit 0

# Let GTK pick Wayland vs Xwayland (forcing GDK_BACKEND=wayland breaks on some setups).
set +e
yad \
  --title="DO2 Vérification" \
  --text="<b>Installation terminée</b>\n\nAvant de remettre cet ordinateur, testez rapidement les applications installées et assurez-vous que tout fonctionne correctement.\n\nVérifiez aussi le Wi-Fi, le son, la webcam et le micro.\n\nSi tout est bon, passez au prochain PC!" \
  --button="Compris:1" \
  --button="Site du projet:0" \
  --width=420 \
  --center \
  --borders=20 \
  --skip-taskbar \
  --no-focus
YAD_RC=$?
set -e

# 0 = « Site du projet », 1 = « Compris »
if [ "$YAD_RC" -eq 0 ]; then
  xdg-open "https://sunsind.github.io/Projet-DO2-NixOS/" 2>/dev/null || true
fi
