#!/usr/bin/env bash
# DO2 — First-boot welcome popup
# Shown exactly once per user (marker file prevents repeat).

MARKER="$HOME/.do2-welcome-shown"

# Already seen — exit silently
[ -f "$MARKER" ] && exit 0

# Mark as seen before doing anything else
touch "$MARKER"

# Show the welcome dialog.
# --question gives us two buttons: OK-label and Cancel-label.
# If the user clicks "Visiter le site", we open Chrome to the project page.
zenity --question \
  --title="Bienvenue sur votre ordinateur DO2 !" \
  --text="<b>Bienvenue !</b>\n\nCet ordinateur vous est offert gratuitement par le projet\n<b>Dons d'ordinateurs, 2e vie</b> — Collège Montmorency.\n\nIl est équipé de NixOS avec tous les logiciels essentiels :\nbureautique (LibreOffice), navigation web (Chrome),\ncommunication (Gmail, Teams, Meet, Outlook, Zoom),\ndessin (Excalidraw), traduction (Dialect), et plus encore.\n\n<small>Pour en savoir plus sur le projet, visitez notre site web !</small>" \
  --ok-label="Visiter le site web" \
  --cancel-label="Fermer" \
  --width=500 \
  --no-wrap 2>/dev/null

# If user clicked "Visiter le site web" (exit code 0), open the browser
if [ $? -eq 0 ]; then
  xdg-open "https://sunsind.github.io/Projet-DO2-NixOS/"
fi
