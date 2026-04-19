#!/usr/bin/env bash
# Setup bureau utilisateur - v8
set -euo pipefail

SETUP_VERSION="8"
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

# ══════════════════════════════════════════════════════════════════════════
# NETTOYAGE DU MENU
# Catégories autorisées : Bureautique (Office), Graphisme (Graphics), Internet (Network)
# Tout le reste est masqué ou déplacé vers Bureautique.
# ══════════════════════════════════════════════════════════════════════════

# Supprimer tous les anciens overrides pour repartir proprement
rm -f "$LOCAL_APPS"/*.desktop 2>/dev/null || true

# ── PASS 1 : Masquer les apps inutiles (par nom) ─────────────────────────
for f in "$APPS_DIR"/*.desktop; do
  [ -f "$f" ] || continue
  bname=$(basename "$f" .desktop)
  name=$(grep '^Name=' "$f" 2>/dev/null | head -1 | cut -d= -f2- || true)
  cats=$(grep '^Categories=' "$f" 2>/dev/null | head -1 | cut -d= -f2- || true)

  should_hide=false

  # Apps inutiles par nom de fichier
  case "$bname" in
    xterm|yelp|nm-connection-editor|orca|onboard|bulky|libreoffice-draw) should_hide=true ;;
  esac

  # Icon browser (toutes variantes)
  case "$name" in
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
# Autorisées : Office (Bureautique), Graphics (Graphisme), Network (Internet)
# Tout le reste → Office (Bureautique)
for f in "$APPS_DIR"/*.desktop; do
  [ -f "$f" ] || continue
  bname=$(basename "$f" .desktop)

  # Sauter si déjà traité (masqué dans pass 1)
  [ -f "$LOCAL_APPS/$bname.desktop" ] && continue

  cats=$(grep '^Categories=' "$f" 2>/dev/null | head -1 | cut -d= -f2- || true)
  [ -z "$cats" ] && continue

  # Si l'app a une catégorie non autorisée, forcer vers Office
  # (même si elle a aussi Office, pour retirer Science/Utility/etc.)
  has_bad=false
  echo "$cats" | grep -qE '(Utility|System|AudioVideo|Audio|Video|Science|Education|Development|Settings|Accessibility)' && has_bad=true

  # Si que des catégories autorisées, ne rien faire
  if ! $has_bad; then
    continue
  fi

  # Forcer vers Office (Bureautique)
  move_to_office "$f"
done

# ══════════════════════════════════════════════════════════════════════════

# Forcer Cinnamon a recharger le menu
update-desktop-database "$LOCAL_APPS" 2>/dev/null || true
xdg-desktop-menu forceupdate 2>/dev/null || true

echo "$SETUP_VERSION" > "$MARKER"

# Relancer Cinnamon pour appliquer les changements de menu
nohup bash -c "sleep 2 && cinnamon --replace" &>/dev/null &

if [ ! -f "$HOME/.do2-welcome-shown" ]; then
  /etc/do2/do2-welcome.sh &
fi
