#!/usr/bin/env bash
# Règles de nettoyage du menu DO2 (partagées entre script principal et tests).

should_hide_app() {
  local bname="$1"
  local name="$2"
  local cats="$3"

  # Apps inutiles par nom de fichier
  case "$bname" in
    xterm|yelp|nm-connection-editor|orca|onboard|bulky|file-roller|gnome-disk-utility|gnome-disks|baobab) return 0 ;;
  esac

  # LibreOffice Draw (toutes variantes de noms)
  case "$bname" in
    *libreoffice*draw*|*LibreOffice*Draw*|*libreoffice*Draw*) return 0 ;;
  esac

  # LibreOffice Draw + Icon Browser (par nom affiché)
  case "$name" in
    *"LibreOffice Draw"*|*"libreoffice draw"*) return 0 ;;
    *"Icon Browser"*|*"icon browser"*) return 0 ;;
  esac

  # Settings : masquer tout sauf Paramètres système et Logiciels
  if echo "$cats" | grep -q 'Settings'; then
    case "$bname" in
      cinnamon-settings|gnome-control-center) ;;
      org.gnome.Software*|gnome-software*) ;;
      *) return 0 ;;
    esac
  fi

  return 1
}

has_disallowed_categories() {
  local cats="$1"
  echo "$cats" | grep -qE '(Utility|System|AudioVideo|Audio|Video|Science|Education|Development|Settings|Accessibility)'
}
