#!/usr/bin/env bash
MARKER="$HOME/.do2-welcome-shown"

[ -f "$MARKER" ] && exit 0
touch "$MARKER"

GDK_BACKEND=wayland yad \
  --title="Bienvenue" \
  --text="Cet ordinateur vous est remis dans le cadre du projet <b>Dons d'ordinateurs, 2e vie</b> du Collège Montmorency, initié par des étudiants pour donner une seconde vie au matériel informatique.\n\nVisitez notre site pour en savoir plus." \
  --button="Fermer:1" \
  --button="Site Web:0" \
  --width=400 \
  --center \
  --borders=20 \
  --skip-taskbar \
  --no-focus 2>/dev/null

if [ $? -eq 0 ]; then
  xdg-open "https://sunsind.github.io/Projet-DO2-NixOS/"
fi
