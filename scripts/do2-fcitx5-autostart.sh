#!/usr/bin/env sh
# Demarre fcitx5 une seule fois (evite conflit D-Bus si deja lance).
if command -v pgrep >/dev/null 2>&1 && pgrep -x fcitx5 >/dev/null 2>&1; then
  exit 0
fi
sleep 3
exec fcitx5 -dr
