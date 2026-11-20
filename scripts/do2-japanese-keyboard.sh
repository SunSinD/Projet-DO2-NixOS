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
  [[ -x /run/current-system/sw/bin/fcitx5 ]]
}

rebuild() {
  echo ""
  echo "=== Reconstruction du systeme ==="
  echo "Ne fermez pas le terminal."
  echo ""
  nixos-rebuild switch --flake "path:$CONFIG#do2" --impure
}

migrate_legacy() {
  if [ -f "$LEGACY_LOCAL" ] && grep -q "japanese-ime" "$LEGACY_LOCAL" 2>/dev/null; then
    mkdir -p /var/lib/do2
    touch "$MARKER"
    mv -- "$LEGACY_LOCAL" /var/lib/do2/japanese-ime.legacy.nix
  fi
}

verify_install() {
  if ! fcitx_installed; then
    echo ""
    echo "ERREUR : le systeme de saisie japonais est absent apres la reconstruction."
    echo "Lancez : update-do2"
    echo "Puis   : do2-japanese-keyboard repair"
    exit 1
  fi
}

usage() {
  cat <<'EOF'
do2-japanese-keyboard — clavier japonais (cet ordinateur seulement)

  enable    Ajoute le clavier japonais sur cet ordinateur, puis redemarrez
  disable   Retire le clavier japonais de cet ordinateur, puis redemarrez
  status    Verifie si le clavier japonais est disponible
  repair    Reconstruit si deja actif (apres update-do2)

Cliquez l'icone clavier en bas a droite -> Mozc (JP) / Clavier (FR).
EOF
}

usage_after_enable() {
  cat <<'EOF'

Le clavier japonais est maintenant disponible sur cet ordinateur.

Redemarrez : sudo reboot

Apres le redemarrage, dans Chrome ou LibreOffice :
  Cliquez l'icone clavier en bas a droite -> Mozc (JP) ou Clavier (FR)
  Tapez konnichiha -> cela devrait donner こんにちは

EOF
}

enable_japanese() {
  if enabled; then
    echo "Le clavier japonais est deja actif sur cet ordinateur."
    if fcitx_installed; then
      usage_after_enable
      return 0
    fi
    echo "Mais le systeme de saisie japonais manque — reconstruction..."
  else
    echo "Ajout du clavier japonais sur cet ordinateur..."
    mkdir -p /var/lib/do2
    touch "$MARKER"
    if ! rebuild; then
      rm -f "$MARKER"
      return 1
    fi
    verify_install
    usage_after_enable
    return
  fi

  rebuild
  verify_install
  echo "Le clavier japonais est maintenant disponible."
  usage_after_enable
}

disable_japanese() {
  if ! enabled; then
    echo "Le clavier japonais n'est pas actif sur cet ordinateur."
    return 0
  fi

  echo "Retrait du clavier japonais..."
  rm -f "$MARKER"
  if ! rebuild; then
    touch "$MARKER"
    return 1
  fi
  echo "Le clavier japonais a ete retire. Redemarrez : sudo reboot"
}

show_status() {
  if enabled; then
    if fcitx_installed; then
      echo "Statut : disponible"
    else
      echo "Statut : incomplet — lancez update-do2 puis do2-japanese-keyboard repair"
    fi
  else
    echo "Statut : non disponible"
  fi
}

repair_japanese() {
  if ! enabled; then
    echo "Le clavier japonais n'est pas actif. Lancez : do2-japanese-keyboard enable"
    exit 1
  fi
  echo "Reconstruction avec le clavier japonais..."
  rebuild
  verify_install
  echo "OK. Redemarrez : sudo reboot"
}

case "${1:-}" in
  enable|disable|repair)
    if [[ $EUID -ne 0 ]]; then
      exec sudo -- "$0" "$1"
    fi
    exec 9>/run/lock/do2-rebuild.lock
    flock -n 9 || { echo "Une autre mise à jour DO2 est en cours." >&2; exit 1; }
    migrate_legacy
    "${1}_japanese"
    ;;
  status)  show_status ;;
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
