#!/usr/bin/env bash
MARKER="$HOME/.do2-welcome-shown"

[ -f "$MARKER" ] && exit 0
touch "$MARKER"

# Wait up to 30 seconds for internet before showing the popup
for i in $(seq 1 30); do
  curl -s --max-time 1 https://sunsind.github.io > /dev/null 2>&1 && break
  sleep 1
done

yad \
  --title="Bienvenue" \
  --text="Cet ordinateur fait partie du projet\n<b>Dons d'ordinateurs, 2e vie</b> du Collège Montmorency.\n\nVisitez notre site pour en savoir plus\nsur le projet et la communauté qui le soutient.\n" \
  --button="Fermer:1" \
  --button="Site Web:0" \
  --width=400 \
  --center \
  --borders=20 \
  --skip-taskbar 2>/dev/null

if [ $? -eq 0 ]; then
  xdg-open "https://sunsind.github.io/Projet-DO2-NixOS/"
fi
