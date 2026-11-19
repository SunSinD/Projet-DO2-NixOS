#!/usr/bin/env bash
set -euo pipefail

SETUP_VERSION="13:$(readlink /run/current-system)"
MARKER="$HOME/.do2-setup-done"
[ -f "$MARKER" ] && [ "$(cat "$MARKER")" = "$SETUP_VERSION" ] && exit 0

APPS_DIR="/run/current-system/sw/share/applications"
LOCAL_APPS="$HOME/.local/share/applications"
mkdir -p "$LOCAL_APPS" "$HOME/.config"

# Charger les règles partagées de nettoyage du menu
RULES_FILE="/etc/do2/do2-menu-rules.sh"
if [ -f "$RULES_FILE" ]; then
  # shellcheck source=/dev/null
  source "$RULES_FILE"
else
  # shellcheck source=/dev/null
  source "$(dirname "$0")/do2-menu-rules.sh"
fi

# ── Fonctions ─────────────────────────────────────────────────────────────
hidden_entry() {
  cat << HIDE
[Desktop Entry]
Name=$1
Type=Application
NoDisplay=true
Hidden=true
HIDE
}

office_entry() {
  sed 's/^Categories=.*/Categories=Office;/' "$1"
}

managed_override() {
  grep -qx 'X-DO2-Managed=true' "$1" ||
    cmp -s "$1" <(hidden_entry "$2") ||
    { [[ -f "$3" ]] && cmp -s "$1" <(office_entry "$3"); } ||
    { [[ -f "$4" ]] && cmp -s "$1" <(office_entry "$4"); }
}

# ── Copier config Cinnamon ────────────────────────────────────────────────
if [ -d /etc/do2/config/cinnamon/spices ]; then
  mkdir -p "$HOME/.config/cinnamon/spices"
  cp -rn /etc/do2/config/cinnamon/spices/* "$HOME/.config/cinnamon/spices/" 2>/dev/null || true
fi

desktop_shortcut() {
  local file="$desktop/$1.desktop" name=$2 command=$3 icon=$4
  [[ -e "$file" || -L "$file" ]] && return 0
  cat > "$file" << EOF
[Desktop Entry]
Name=$name
Exec=$command
Icon=$icon
Terminal=false
Type=Application
EOF
  chmod +x "$file"
}

desktop=$(xdg-user-dir DESKTOP 2>/dev/null) || desktop="$HOME/Desktop"
if [[ ! -f "$MARKER" && -n "$desktop" && "$desktop" != "$HOME" ]]; then
  mkdir -p "$desktop"
  desktop_shortcut libreoffice-writer "LibreOffice Writer" "libreoffice --writer %U" libreoffice-writer
  desktop_shortcut libreoffice-calc "LibreOffice Calc" "libreoffice --calc %U" libreoffice-calc
  desktop_shortcut Guide-DO2 "Guide DO2" "xdg-open /etc/do2/guides/Guide-DO2.html" help-contents
  if [[ -e "$APPS_DIR/do2-install.desktop" && ! -e "$desktop/Installer-DO2.desktop" ]]; then
    install -m 755 "$APPS_DIR/do2-install.desktop" "$desktop/Installer-DO2.desktop"
  fi
fi

for override in "$LOCAL_APPS"/*.desktop; do
  [[ -f "$override" ]] || continue
  file=${override##*/}
  if managed_override "$override" "${file%.desktop}" "$APPS_DIR/$file" "/run/booted-system/sw/share/applications/$file"; then
    rm -- "$override"
  fi
done

for f in "$APPS_DIR"/*.desktop; do
  [ -f "$f" ] || continue
  file=${f##*/}
  bname=${file%.desktop}
  override="$LOCAL_APPS/$file"
  [[ ! -e "$override" ]] || continue
  name=$(grep '^Name=' "$f" 2>/dev/null | head -1 | cut -d= -f2- || true)
  cats=$(grep '^Categories=' "$f" 2>/dev/null | head -1 | cut -d= -f2- || true)

  if should_hide_app "$bname" "$name" "$cats"; then
    hidden_entry "$bname" > "$override"
  elif has_disallowed_categories "$cats"; then
    office_entry "$f" > "$override"
  else
    continue
  fi
  sed -i '/^\[Desktop Entry\]$/a X-DO2-Managed=true' "$override"
done

# ══════════════════════════════════════════════════════════════════════════

# Forcer Cinnamon a recharger le menu
update-desktop-database "$LOCAL_APPS" 2>/dev/null || true
xdg-desktop-menu forceupdate 2>/dev/null || true

# Rafraichir le menu Cinnamon sans redemarrer le bureau
dbus-send --session --type=method_call --dest=org.Cinnamon \
  /org/Cinnamon org.Cinnamon.Eval \
  string:'const appSys = imports.gi.Cinnamon.AppSystem.get_default(); appSys.notify("installed-changed");' \
  2>/dev/null || true

echo "$SETUP_VERSION" > "$MARKER"

if [ ! -f "$HOME/.do2-welcome-shown" ] && ! command -v do2-install >/dev/null; then
  /etc/do2/do2-welcome.sh &
fi
