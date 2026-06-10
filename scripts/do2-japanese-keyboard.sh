#!/usr/bin/env bash
# Active ou desactive le clavier japonais (IME Mozc) sur ce portable seulement.
set -euo pipefail

CONFIG="/etc/nixos/config"
LOCAL="$CONFIG/local.nix"
MARKER="$CONFIG/.do2-japanese-enabled"

enabled() {
  [ -f "$LOCAL" ] && grep -q "japanese-ime.nix" "$LOCAL" 2>/dev/null
}

rebuild() {
  echo "Reconstruction du systeme (quelques minutes)..."
  sudo nixos-rebuild switch --flake "$CONFIG#do2"
}

enable_japanese() {
  if enabled; then
    yad --info --title="Clavier japonais" --text="Le clavier japonais est deja active sur cet ordinateur.\n\nRaccourci : Ctrl + Maj + Espace" --button="OK" 2>/dev/null \
      || echo "Le clavier japonais est deja active. Raccourci : Ctrl + Maj + Espace"
    return 0
  fi

  sudo tee "$LOCAL" > /dev/null <<'EOF'
# Active localement sur ce portable (preserve par update-do2).
{ ... }: {
  imports = [ ./modules/japanese-ime.nix ];
}
EOF
  sudo touch "$MARKER"
  rebuild

  yad --info --title="Clavier japonais" --text="Clavier japonais active.\n\nRaccourci : Ctrl + Maj + Espace\n(Maj = touche Shift)\n\nRedemarrez si le raccourci ne fonctionne pas tout de suite." --button="OK" 2>/dev/null \
    || echo "Clavier japonais active. Raccourci : Ctrl + Maj + Espace"
}

disable_japanese() {
  if ! enabled; then
    yad --info --title="Clavier japonais" --text="Le clavier japonais n'est pas active sur cet ordinateur." --button="OK" 2>/dev/null \
      || echo "Le clavier japonais n'est pas active."
    return 0
  fi

  ans=$(yad --question --title="Clavier japonais" --text="Desactiver le clavier japonais sur cet ordinateur ?" --button="Oui:0" --button="Non:1" 2>/dev/null || echo "0")
  [ "$ans" = "1" ] && return 0

  sudo rm -f "$LOCAL" "$MARKER"
  rebuild

  yad --info --title="Clavier japonais" --text="Clavier japonais desactive." --button="OK" 2>/dev/null \
    || echo "Clavier japonais desactive."
}

show_menu() {
  if enabled; then
    status="active"
    choice=$(yad --title="Clavier japonais" --width=420 \
      --text="Statut : active sur cet ordinateur.\n\nRaccourci : Ctrl + Maj + Espace (Maj = Shift)\nTapez en alphabet latin, ex. konnichiha → こんにちは" \
      --button="Desactiver:1" --button="Fermer:0" 2>/dev/null || echo "0")
    [ "$choice" = "1" ] && disable_japanese
  else
    choice=$(yad --title="Clavier japonais" --width=420 \
      --text="Le clavier japonais n'est pas installe sur cet ordinateur.\n\nL'activation prend quelques minutes et ne concerne que ce portable." \
      --button="Activer:1" --button="Fermer:0" 2>/dev/null || echo "0")
    [ "$choice" = "1" ] && enable_japanese
  fi
}

if [ "$(id -u)" -eq 0 ]; then
  echo "Lancez cette commande sans sudo : do2-japanese-keyboard"
  exit 1
fi

case "${1:-menu}" in
  enable)  enable_japanese ;;
  disable) disable_japanese ;;
  menu|*)  show_menu ;;
esac
