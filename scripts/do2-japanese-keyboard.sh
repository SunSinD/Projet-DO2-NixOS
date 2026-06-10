#!/usr/bin/env bash
# Active ou desactive le clavier japonais (IME Mozc) sur ce portable seulement.
set -euo pipefail

CONFIG="/etc/nixos/config"
MARKER="/var/lib/do2/japanese-ime.enabled"
LEGACY_LOCAL="$CONFIG/local.nix"

enabled() {
  [ -f "$MARKER" ]
}

fcitx_installed() {
  command -v fcitx5 >/dev/null 2>&1
}

fcitx5_running() {
  pgrep -x fcitx5 >/dev/null 2>&1 && return 0
  fcitx5-remote -p >/dev/null 2>&1
}

stop_fcitx() {
  fcitx5-remote -e >/dev/null 2>&1 || true
  pkill -x fcitx5 >/dev/null 2>&1 || true
  sleep 1
}

rebuild() {
  echo ""
  echo "=== Reconstruction du systeme ==="
  echo "Ne fermez pas le terminal."
  echo ""
  sudo nixos-rebuild switch --flake "$CONFIG#do2" --impure
  echo ""
}

migrate_legacy() {
  if [ -f "$LEGACY_LOCAL" ] && grep -q "japanese-ime" "$LEGACY_LOCAL" 2>/dev/null; then
    sudo mkdir -p /var/lib/do2
    sudo touch "$MARKER"
    sudo rm -f "$LEGACY_LOCAL"
  fi
}

verify_install() {
  if ! fcitx_installed; then
    echo ""
    echo "ERREUR: fcitx5 absent du systeme apres le rebuild."
    echo "Lancez : update-do2"
    echo "Puis   : do2-japanese-keyboard repair"
    exit 1
  fi
}

usage() {
  cat <<'EOF'
do2-japanese-keyboard — clavier japonais (cet ordinateur seulement)

  enable    Installe le clavier japonais, puis redemarrez
  disable   Retire le clavier japonais, puis redemarrez
  status    Verifie si le clavier japonais est installe
  start     Demarre fcitx5 maintenant (si arrete)
  repair    Reconstruit si deja active (apres update-do2)

Raccourcis : Ctrl + Shift + Espace  ou  Alt + Shift + J
Ou cliquez l'icone clavier en bas a droite → Mozc (JP) / Clavier (FR).
EOF
}

start_fcitx() {
  if ! enabled; then
    echo "Clavier japonais non installe. Lancez : do2-japanese-keyboard enable"
    exit 1
  fi
  if ! fcitx_installed; then
    echo "fcitx5 manquant. Lancez : do2-japanese-keyboard repair"
    exit 1
  fi
  if fcitx5_running; then
    echo "fcitx5 deja en cours d'execution."
    return 0
  fi
  stop_fcitx
  fcitx5 -dr
  sleep 1
  if fcitx5_running; then
    echo "fcitx5 demarre. Essayez Ctrl + Shift + Espace ou Alt + Shift + J."
  else
    echo "Echec du demarrage de fcitx5."
    exit 1
  fi
}

usage_after_enable() {
  cat <<'EOF'

Francais par defaut.

  Ctrl + Shift + Espace  ou  Alt + Shift + J  = basculer FR / JP
  Icone clavier en bas a droite : Clavier (FR) ou Mozc (JP)

Redemarrez : sudo reboot

EOF
}

enable_japanese() {
  migrate_legacy

  if enabled; then
    echo "Deja active sur cet ordinateur."
    if fcitx_installed; then
      usage_after_enable
      return 0
    fi
    echo "Mais fcitx5 manque — reconstruction..."
  else
    echo "Activation du clavier japonais sur cet ordinateur..."
    sudo mkdir -p /var/lib/do2
    sudo touch "$MARKER"
    sudo rm -f "$LEGACY_LOCAL"
  fi

  rebuild
  verify_install
  echo "Clavier japonais installe."
  usage_after_enable
}

disable_japanese() {
  migrate_legacy

  if ! enabled; then
    echo "Non installe sur cet ordinateur."
    return 0
  fi

  echo "Desactivation du clavier japonais..."
  sudo rm -f "$MARKER" "$LEGACY_LOCAL"
  rebuild
  echo "Clavier japonais desactive. Redemarrez : sudo reboot"
}

show_status() {
  migrate_legacy

  if enabled; then
    echo "Statut : active"
    if fcitx_installed; then
      echo "fcitx5 : installe"
      if fcitx5_running; then
        echo "fcitx5 : en cours d'execution"
      else
        echo "fcitx5 : arrete — lancez : do2-japanese-keyboard start"
      fi
    else
      echo "fcitx5 : MANQUANT — lancez : update-do2 puis do2-japanese-keyboard repair"
    fi
  else
    echo "Statut : non installe"
  fi
}

repair_japanese() {
  migrate_legacy

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
  start)   start_fcitx ;;
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
