#!/usr/bin/env bash
set -euo pipefail

MARKER="$HOME/.do2-welcome-shown"
[ -f "$MARKER" ] && exit 0
touch "$MARKER"

command -v yad >/dev/null 2>&1 || exit 0

set +e
yad \
  --title="Bienvenue" \
  --text="<b>Vérification post-installation</b>\n\nAvant de remettre cet ordinateur, vérifiez :\n\n<b>Matériel :</b>\n• Wi-Fi : connexion au réseau\n• Son : volume et haut-parleurs\n• Webcam : ouvrez <b>OBS Studio</b> et ajoutez une source <b>Périphérique de capture vidéo</b> pour tester\n• Micro : test rapide\n• Clavier : toutes les touches\n• Écran : luminosité et affichage\n\n<b>Logiciels :</b>\n• Google Chrome s'ouvre sans popup\n• LibreOffice Writer et Calc fonctionnent\n• Zoom se lance correctement\n• Dialect (traducteur) fonctionne\n\nSi tout est bon, passez au prochain PC!" \
  --button="Compris:1" \
  --width=420 \
  --height=420 \
  --fixed \
  --center \
  --borders=15 \
  --skip-taskbar
set -e
