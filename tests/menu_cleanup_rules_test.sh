#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/do2-menu-rules.sh"

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; exit 1; }

assert_hide() {
  local desc="$1" bname="$2" name="$3" cats="$4"
  if should_hide_app "$bname" "$name" "$cats"; then
    pass "$desc"
  else
    fail "$desc"
  fi
}

assert_not_hide() {
  local desc="$1" bname="$2" name="$3" cats="$4"
  if should_hide_app "$bname" "$name" "$cats"; then
    fail "$desc"
  else
    pass "$desc"
  fi
}

assert_move() {
  local desc="$1" cats="$2"
  if has_disallowed_categories "$cats"; then
    pass "$desc"
  else
    fail "$desc"
  fi
}

assert_no_move() {
  local desc="$1" cats="$2"
  if has_disallowed_categories "$cats"; then
    fail "$desc"
  else
    pass "$desc"
  fi
}

assert_hide "Hide known utility app by desktop filename" "xterm" "XTerm" "System;TerminalEmulator;"
assert_hide "Hide LibreOffice Draw by display name" "libreoffice-startcenter" "LibreOffice Draw" "Office;"
assert_hide "Hide Icon Browser by display name" "mint-icon-browser" "Icon Browser" "Graphics;"
assert_not_hide "Keep system settings app visible" "cinnamon-settings" "Paramètres système" "Settings;"
assert_not_hide "Keep allowed Network app visible" "google-chrome" "Google Chrome" "Network;WebBrowser;"

assert_move "Move entries with Utility category to Office override path" "Office;Utility;"
assert_move "Move entries with Settings category to Office override path" "Settings;GTK;"
assert_no_move "Do not move entries with only allowed categories" "Office;Network;"

echo "All menu cleanup rule tests passed."
