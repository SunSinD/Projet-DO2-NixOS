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
  --title="Bienvenue — DO2" \
  --text="Cet ordinateur vous est offert gratuitement\npar le <b>Collège Montmorency</b>.\n\nVisitez notre site pour en savoir plus\nsur le projet <b>Dons d'ordinateurs, 2e vie</b>." \
  --button="FERMER:1" \
  --button="VISITER LE SITE WEB:0" \
  --width=400 \
  --center \
  --borders=20 2>/dev/null

if [ $? -eq 0 ]; then
  xdg-open "https://sunsind.github.io/Projet-DO2-NixOS/"
fi
