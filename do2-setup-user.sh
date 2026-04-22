#!/usr/bin/env bash
# Setup bureau utilisateur - v12
set -euo pipefail

SETUP_VERSION="12"
MARKER="$HOME/.do2-setup-done"
if [ -f "$MARKER" ]; then
  [ "$(cat "$MARKER" 2>/dev/null)" = "$SETUP_VERSION" ] && exit 0
fi

APPS_DIR="/run/current-system/sw/share/applications"
LOCAL_APPS="$HOME/.local/share/applications"
mkdir -p "$HOME/Desktop" "$HOME/Documents" "$HOME/Downloads" "$HOME/Pictures"
mkdir -p "$LOCAL_APPS" "$HOME/.config"

# ── Fonctions ─────────────────────────────────────────────────────────────
hide_app() {
  cat > "$LOCAL_APPS/$1.desktop" << HIDE
[Desktop Entry]
Name=$1
Type=Application
NoDisplay=true
Hidden=true
HIDE
}

move_to_office() {
  local src="$1"
  local bname=$(basename "$src")
  cp "$src" "$LOCAL_APPS/$bname"
  if grep -q '^Categories=' "$LOCAL_APPS/$bname"; then
    sed -i 's/^Categories=.*/Categories=Office;/' "$LOCAL_APPS/$bname"
  else
    echo "Categories=Office;" >> "$LOCAL_APPS/$bname"
  fi
}

# ── Copier config Cinnamon ────────────────────────────────────────────────
if [ -d /etc/do2/config/cinnamon/spices ]; then
  mkdir -p "$HOME/.config/cinnamon/spices"
  cp -rn /etc/do2/config/cinnamon/spices/* "$HOME/.config/cinnamon/spices/" 2>/dev/null || true
fi

# ── Raccourcis bureau ─────────────────────────────────────────────────────
cat > "$HOME/Desktop/libreoffice-writer.desktop" << 'EOF'
[Desktop Entry]
Name=LibreOffice Writer
Exec=libreoffice --writer %U
Icon=libreoffice-writer
Terminal=false
Type=Application
Categories=Office;
EOF
chmod +x "$HOME/Desktop/libreoffice-writer.desktop"

cat > "$HOME/Desktop/libreoffice-calc.desktop" << 'EOF'
[Desktop Entry]
Name=LibreOffice Calc
Exec=libreoffice --calc %U
Icon=libreoffice-calc
Terminal=false
Type=Application
Categories=Office;
EOF
chmod +x "$HOME/Desktop/libreoffice-calc.desktop"

cat > "$HOME/Desktop/Guide-DO2.desktop" << 'EOF'
[Desktop Entry]
Name=Guide DO2
Exec=xdg-open /etc/do2/guides/Guide-DO2.html
Icon=help-contents
Terminal=false
Type=Application
EOF
chmod +x "$HOME/Desktop/Guide-DO2.desktop"

# ── Associations de fichiers ──────────────────────────────────────────────
cat > "$HOME/.config/mimeapps.list" << 'EOF'
[Default Applications]
text/html=google-chrome.desktop
x-scheme-handler/http=google-chrome.desktop
x-scheme-handler/https=google-chrome.desktop
application/pdf=google-chrome.desktop
inode/directory=nemo.desktop
EOF

# ── GoldenDict-ng — mode nuit pour les articles ───────────────────────────
GDCONFIG="$HOME/.config/GoldenDict/config"
mkdir -p "$(dirname "$GDCONFIG")"
if [ ! -f "$GDCONFIG" ]; then
  cat > "$GDCONFIG" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<config>
 <preferences>
  <nightMode>true</nightMode>
 </preferences>
</config>
EOF
else
  if grep -q "<nightMode>false</nightMode>" "$GDCONFIG"; then
    sed -i 's|<nightMode>false</nightMode>|<nightMode>true</nightMode>|' "$GDCONFIG"
  elif ! grep -q "<nightMode>" "$GDCONFIG"; then
    sed -i 's|</preferences>|  <nightMode>true</nightMode>\n</preferences>|' "$GDCONFIG"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════
# NETTOYAGE DU MENU
# Catégories autorisées : Bureautique (Office), Graphisme (Graphics), Internet (Network)
# Tout le reste est masqué ou déplacé vers Bureautique.
# ══════════════════════════════════════════════════════════════════════════

# ── PASS 1 : Masquer les apps inutiles (par nom) ─────────────────────────
for f in "$APPS_DIR"/*.desktop; do
  [ -f "$f" ] || continue
  bname=$(basename "$f" .desktop)
  name=$(grep '^Name=' "$f" 2>/dev/null | head -1 | cut -d= -f2- || true)
  cats=$(grep '^Categories=' "$f" 2>/dev/null | head -1 | cut -d= -f2- || true)

  should_hide=false

  # Apps inutiles par nom de fichier
  case "$bname" in
    xterm|yelp|nm-connection-editor|orca|onboard|bulky|file-roller|gnome-disk-utility|gnome-disks|baobab) should_hide=true ;;
  esac

  # LibreOffice Draw (toutes variantes de noms)
  case "$bname" in
    *libreoffice*draw*|*LibreOffice*Draw*|*libreoffice*Draw*) should_hide=true ;;
  esac

  # LibreOffice Draw + Icon browser (par nom affiché)
  case "$name" in
    *"LibreOffice Draw"*|*"libreoffice draw"*) should_hide=true ;;
    *"con"*"rowser"*|*"con"*"Browser"*) should_hide=true ;;
  esac

  # Settings : masquer tout sauf Paramètres système et Logiciels
  if echo "$cats" | grep -q 'Settings'; then
    case "$bname" in
      cinnamon-settings|gnome-control-center) ;;
      org.gnome.Software*|gnome-software*) ;;
      *) should_hide=true ;;
    esac
  fi

  if $should_hide; then
    hide_app "$bname"
  fi
done

# ── PASS 2 : Déplacer les apps des catégories non autorisées ─────────────
for f in "$APPS_DIR"/*.desktop; do
  [ -f "$f" ] || continue
  bname=$(basename "$f" .desktop)

  [ -f "$LOCAL_APPS/$bname.desktop" ] && continue

  cats=$(grep '^Categories=' "$f" 2>/dev/null | head -1 | cut -d= -f2- || true)
  [ -z "$cats" ] && continue

  has_bad=false
  echo "$cats" | grep -qE '(Utility|System|AudioVideo|Audio|Video|Science|Education|Development|Settings|Accessibility)' && has_bad=true

  if ! $has_bad; then
    continue
  fi

  move_to_office "$f"
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

if [ ! -f "$HOME/.do2-welcome-shown" ]; then
  /etc/do2/do2-welcome.sh &
fi
