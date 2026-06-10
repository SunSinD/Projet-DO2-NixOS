#!/usr/bin/env sh
# Demarre fcitx5 apres connexion (clavier japonais opt-in seulement).
mkdir -p "$HOME/.config/mozc" "$HOME/.config/fcitx5"
sleep 4
if pgrep -x fcitx5 >/dev/null 2>&1; then
  exit 0
fi
export DISPLAY="${DISPLAY:-:0}"
exec fcitx5 -d
