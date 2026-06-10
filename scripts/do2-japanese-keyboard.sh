#!/usr/bin/env bash
# Active ou desactive le clavier japonais (IME Mozc) sur ce portable seulement.
set -euo pipefail

CONFIG="/etc/nixos/config"
LOCAL="$CONFIG/local.nix"
MARKER="$CONFIG/.do2-japanese-enabled"

enabled() {
  [ -f "$LOCAL" ] && grep -q "japanese-ime.nix" "$LOCAL" 2>/dev/null
}

has_gui() {
  [ -n "${DISPLAY:-}" ] && command -v yad >/dev/null 2>&1
}

rebuild() {
  echo ""
  echo "=== Reconstruction du systeme (10 a 20 minutes) ==="
  echo "Ne fermez pas le terminal."
  echo ""
  sudo nixos-rebuild switch --flake "$CONFIG#do2"
  echo ""
  echo "=== Termine. Redemarrez : sudo reboot ==="
}

usage_after_enable() {
  cat <<'EOF'

Clavier japonais installe sur CET ordinateur seulement.
Francais par defaut.

  Ctrl + Maj + Espace  = basculer francais / japonais
  (Maj = touche Shift, barre d'espace)

Ou cliquez l'icone en bas a droite : Clavier (FR) ou Mozc (JP).

EOF
}

enable_japanese() {
  if enabled; then
    echo "Le clavier japonais est deja installe sur cet ordinateur."
    usage_after_enable
    return 0
  fi

  echo "Activation du clavier japonais sur cet ordinateur..."
  sudo tee "$LOCAL" > /dev/null <<'EOF'
# Active localement sur ce portable (preserve par update-do2).
{ ... }: {
  imports = [ ./modules/japanese-ime.nix ];
}
EOF
  sudo touch "$MARKER"
  rebuild
  echo "Clavier japonais active."
  usage_after_enable
}

disable_japanese() {
  if ! enabled; then
    echo "Le clavier japonais n'est pas installe sur cet ordinateur."
    return 0
  fi

  echo "Desactivation du clavier japonais..."
  sudo rm -f "$LOCAL" "$MARKER"
  rebuild
  echo "Clavier japonais desactive."
}

show_menu_gui() {
  if enabled; then
    choice=$(yad --title="Clavier japonais" --width=420 \
      --text="Statut : installe sur cet ordinateur.\n\nFrancais par defaut. Ctrl + Maj + Espace bascule FR/JP.\nIcone en bas a droite : Clavier (FR) ou Mozc (JP)." \
      --button="Desactiver:1" --button="Fermer:0" 2>/dev/null || echo "0")
    [ "$choice" = "1" ] && disable_japanese
  else
    choice=$(yad --title="Clavier japonais" --width=420 \
      --text="Le clavier japonais n'est pas installe.\n\nL'activation prend 10 a 20 minutes et ne concerne que ce portable." \
      --button="Activer:1" --button="Fermer:0" 2>/dev/null || echo "0")
    [ "$choice" = "1" ] && enable_japanese
  fi
}

show_menu_terminal() {
  echo "=== Clavier japonais (DO2) ==="
  if enabled; then
    echo "Statut : installe sur cet ordinateur."
    usage_after_enable
    echo "  1) Desactiver (rebuild)"
    echo "  2) Annuler"
    read -r -p "Choix [2] : " choice
    case "${choice:-2}" in
      1) disable_japanese ;;
      *) echo "Annule." ;;
    esac
  else
    echo "Le clavier japonais n'est pas installe sur cet ordinateur."
    echo "L'activation prend 10 a 20 minutes."
    echo ""
    echo "  1) Activer"
    echo "  2) Annuler"
    read -r -p "Choix [2] : " choice
    case "${choice:-2}" in
      1) enable_japanese ;;
      *) echo "Annule. Pour activer plus tard : do2-japanese-keyboard enable" ;;
    esac
  fi
}

show_menu() {
  if has_gui; then
    show_menu_gui
  else
    show_menu_terminal
  fi
}

if [ "$(id -u)" -eq 0 ]; then
  echo "Lancez sans sudo : do2-japanese-keyboard"
  exit 1
fi

case "${1:-menu}" in
  enable)  enable_japanese ;;
  disable) disable_japanese ;;
  status)
    if enabled; then
      echo "Statut : installe"
    else
      echo "Statut : non installe"
    fi
    ;;
  menu|*)
    show_menu
    ;;
esac
