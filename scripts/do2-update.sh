#!/usr/bin/env bash
set -euo pipefail

CONFIG=/etc/nixos/config
exec 9>/run/lock/do2-rebuild.lock
flock -n 9 || { echo "Une autre mise à jour DO2 est en cours." >&2; exit 1; }

if [[ ! -s "$CONFIG/hardware-configuration.nix" ]]; then
  echo "Configuration matérielle introuvable dans $CONFIG." >&2
  exit 1
fi
root_source=$(findmnt -nro SOURCE --mountpoint /)
root_disk=$(lsblk -snrpo NAME,TYPE "$root_source" | awk '$2 == "disk" { print $1 }')
if [[ ! -b "$root_disk" ]]; then
  echo "Impossible d'identifier le disque DO2 qui contient /." >&2
  exit 1
fi
device=$(stable_disk_path "$root_disk")

work=$(mktemp -d /etc/nixos/.do2-update.XXXXXXXX)
trap 'rm -rf -- "$work"' EXIT

next="$work/config"
echo "[1/3] Téléchargement de la configuration DO2…"
repo=$(git -C "$CONFIG" remote get-url origin)
git clone --depth 1 --branch release -- "$repo" "$next"
cp "$CONFIG/hardware-configuration.nix" "$next/hardware-configuration.nix"
if [[ -f "$CONFIG/local.nix" ]]; then
  cp "$CONFIG/local.nix" "$next/local.nix"
fi
sed -i "s|device = \"/dev/sda\"; # DO2_DISK|device = \"$device\"; # DO2_DISK|" "$next/flake.nix"

echo "[2/3] Reconstruction du système…"
nixos-rebuild switch --flake "path:$next#do2" --impure "$@"

echo "[3/3] Enregistrement de la configuration…"
mv -T --exchange --no-copy -- "$next" "$CONFIG"
echo "Mise à jour terminée. Redémarrez avec sudo reboot."
