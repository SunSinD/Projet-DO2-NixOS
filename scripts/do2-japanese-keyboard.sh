#!/usr/bin/env bash
# Active ou desactive le clavier japonais (IME Mozc) sur ce portable seulement.
set -euo pipefail

CONFIG="/etc/nixos/config"
LOCAL="$CONFIG/local.nix"
MARKER="$CONFIG/.do2-japanese-enabled"

enabled() {
  [ -f "$LOCAL" ] && grep -q "japanese-ime.nix" "$LOCAL" 2>/dev/null
}

fcitx_installed() {
  command -v fcitx5 >/dev/null 2>&1
}

rebuild() {
  echo ""
  echo "=== Reconstruction du systeme (10 a 20 minutes) ==="
  echo "Ne fermez pas le terminal."
  echo ""
  sudo nixos-rebuild switch --flake "$CONFIG#do2"
  echo ""
}

verify_install() {
  if ! fcitx_installed; then
    echo ""
    echo "ERREUR: fcitx5 absent du systeme apres le rebuild."
    echo "Lancez : update-do2"
    echo "Puis   : do2-japanese-keyboard enable"
    exit 1
  fi
}

usage() {
  cat <<'EOF'
do2-japanese-keyboard — clavier japonais (cet ordinateur seulement)

  enable    Installe le clavier japonais (rebuild ~10-20 min, puis reboot)
  disable   Retire le clavier japonais
  status    Affiche si installe et si fcitx5 est present
  repair    Reconstruit si deja active (apres une mise a jour DO2)

Apres reboot : Ctrl + Maj + Espace pour basculer francais / japonais.
(Maj = Shift, barre d'espace — pas la touche Esc)
EOF
}

usage_after_enable() {
  cat <<'EOF'

Francais par defaut. Ctrl + Maj + Espace = basculer vers le japonais.
Icone clavier en bas a droite : Clavier (FR) ou Mozc (JP).

Redemarrez maintenant : sudo reboot

EOF
}

enable_japanese() {
  if enabled; then
    echo "Deja active sur cet ordinateur."
    if fcitx_installed; then
      usage_after_enable
      return 0
    fi
    echo "Mais fcitx5 manque — reconstruction..."
  else
    echo "Activation du clavier japonais sur cet ordinateur..."
    sudo tee "$LOCAL" > /dev/null <<'EOF'
# Active localement sur ce portable (preserve par update-do2).
{ ... }: {
  imports = [ /etc/nixos/config/modules/japanese-ime.nix ];
}
EOF
    sudo touch "$MARKER"
  fi

  rebuild
  verify_install
  echo "Clavier japonais installe."
  usage_after_enable
}

disable_japanese() {
  if ! enabled; then
    echo "Non installe sur cet ordinateur."
    return 0
  fi

  echo "Desactivation du clavier japonais..."
  sudo rm -f "$LOCAL" "$MARKER"
  rebuild
  echo "Clavier japonais desactive. Redemarrez : sudo reboot"
}

show_status() {
  if enabled; then
    echo "Statut : active (local.nix present)"
    if fcitx_installed; then
      echo "fcitx5 : installe"
      if pgrep -x fcitx5 >/dev/null 2>&1; then
        echo "fcitx5 : en cours d'execution"
      else
        echo "fcitx5 : arrete (redemarrez ou lancez : fcitx5 -d)"
      fi
    else
      echo "fcitx5 : MANQUANT — lancez : update-do2 puis do2-japanese-keyboard repair"
    fi
  else
    echo "Statut : non installe"
  fi
}

repair_japanese() {
  if ! enabled; then
    echo "Pas active. Lancez : do2-japanese-keyboard enable"
    exit 1
  fi
  echo "Reconstruction avec le clavier japonais..."
  rebuild
  verify_install
  echo "OK. Redemarrez : sudo reboot"
}

if [ "$(id -u)" -eq 0 ]; then
  echo "Lancez sans sudo : do2-japanese-keyboard enable"
  exit 1
fi

case "${1:-}" in
  enable)  enable_japanese ;;
  disable) disable_japanese ;;
  status)  show_status ;;
  repair)  repair_japanese ;;
  help|-h|--help) usage ;;
  "")
    usage
    echo ""
    show_status
    ;;
  *)
    echo "Option inconnue : $1"
    echo ""
    usage
    exit 1
    ;;
esac
