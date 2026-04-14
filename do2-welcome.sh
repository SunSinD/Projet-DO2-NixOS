#!/usr/bin/env bash
MARKER="$HOME/.do2-welcome-shown"

[ -f "$MARKER" ] && exit 0
touch "$MARKER"

GDK_BACKEND=wayland yad \
  --title="DO2 — Vérification" \
  --text="<b>Installation terminée ✓</b>\n\nAvant de remettre cet ordinateur, vérifiez rapidement :\n\n• Wi-Fi fonctionnel\n• Son fonctionnel\n• Chrome, LibreOffice, Zoom s'ouvrent\n• Webcam et micro (si applicable)\n\nSi tout est bon, vous pouvez passer au prochain !" \
  --button="Compris:1" \
  --button="Site du projet:0" \
  --width=420 \
  --center \
  --borders=20 \
  --skip-taskbar \
  --no-focus 2>/dev/null

if [ $? -eq 0 ]; then
  xdg-open "https://sunsind.github.io/Projet-DO2-NixOS/"
fi
