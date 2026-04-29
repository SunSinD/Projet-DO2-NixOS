#!/usr/bin/env bash
set -euo pipefail

# DO2 - installateur complet (telecharge par le bootstrap `do2` ou `install.sh`).
INSTALL_SCRIPT_REV="2026-04-18.2"

FLAKE_ATTR="do2"
WORK_DIR="/tmp/do2config"

export NIX_CONFIG="experimental-features = nix-command flakes"

cleanup() {
  sudo swapoff /mnt/var/lib/swapfile 2>/dev/null || true
  sudo umount -lR /mnt               2>/dev/null || true
}
trap cleanup EXIT

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║   DO2 - Dons d'ordinateurs, 2e vie   ║"
echo "  ║   Installation automatique NixOS     ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

sudo umount -lR /mnt 2>/dev/null || true
sudo swapoff -a      2>/dev/null || true

echo "  [1/6] Preparation de la configuration..."
cd "$WORK_DIR"

# ── Sélection du disque ──────────────────────────────────────────────────
ISO_SOURCE=$(findmnt -n -o SOURCE /iso 2>/dev/null || true)
ISO_DISK=""
if [[ -n "$ISO_SOURCE" ]]; then
  ISO_DISK=$(lsblk -no PKNAME "$ISO_SOURCE" 2>/dev/null || true)
fi

mapfile -t DISK_NAMES < <(
  lsblk -dn -o NAME,TYPE -e 7 \
    | awk '$2 == "disk" { print $1 }' \
    | { if [[ -n "$ISO_DISK" ]]; then grep -v "^${ISO_DISK}$" || true; else cat; fi; }
)

if [[ ${#DISK_NAMES[@]} -eq 0 ]]; then
  echo "  ERREUR : aucun disque détecté."
  exit 1
fi

echo ""
echo "  Disques disponibles :"
echo ""

idx=0
for disk_name in "${DISK_NAMES[@]}"; do
  disk_size=$(lsblk -dno SIZE "/dev/${disk_name}" 2>/dev/null || echo "?")
  disk_model=$(lsblk -dno MODEL "/dev/${disk_name}" 2>/dev/null || echo "")
  echo "    [$idx]  /dev/${disk_name}  ${disk_size}  ${disk_model}"
  idx=$((idx + 1))
done

echo ""
exec < /dev/tty
read -rp "  Choisissez un disque [0-$((${#DISK_NAMES[@]} - 1))] : " CHOICE

if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [[ "$CHOICE" -ge ${#DISK_NAMES[@]} ]]; then
  echo "  ERREUR : choix invalide."
  exit 1
fi

DEV="/dev/${DISK_NAMES[$CHOICE]}"

if lsblk -no TRAN "$DEV" 2>/dev/null | grep -q "usb"; then
  echo "  ERREUR : $DEV est une clé USB. Choisissez le disque interne."
  exit 1
fi

echo ""
echo "  Disque sélectionné : $DEV"
echo ""
read -rp "  TOUTES LES DONNÉES SUR $DEV SERONT EFFACÉES. Confirmer ? (oui/non) : " CONFIRM

if [[ "$CONFIRM" != "oui" ]]; then
  echo "  Installation annulée."
  exit 1
fi

echo ""
echo "  [2/6] Partitionnement de $DEV..."
sed -i "s|device = \"/dev/[^\"]*\"; # DO2_DISK|device = \"$DEV\"; # DO2_DISK|" flake.nix
git add flake.nix
echo "{ }" > hardware-configuration.nix
git add hardware-configuration.nix
sudo nix --extra-experimental-features "nix-command flakes" run \
  github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --yes-wipe-all-disks \
  --flake ".#$FLAKE_ATTR" 2>&1 | { grep -v '^warning:' || true; }

echo ""
echo "  [3/6] Détection du matériel..."
sudo nixos-generate-config --root /mnt --no-filesystems 2>/dev/null
sudo cp /mnt/etc/nixos/hardware-configuration.nix "$WORK_DIR/hardware-configuration.nix"
git add hardware-configuration.nix

nix --extra-experimental-features "nix-command flakes" flake update 2>/dev/null || true
git add . 2>/dev/null
git -c user.email="do2@montmorency.qc.ca" \
    -c user.name="DO2-Installer" \
    commit -q --allow-empty -m "Configuration locale pour $(hostname)" 2>/dev/null || true

echo ""
echo "  [4/6] Configuration du swap..."
ram_gb=$(awk '/MemTotal/ { printf "%d", ($2/1024/1024)+0.5 }' /proc/meminfo)
if [[ "$ram_gb" -lt 2 ]]; then
  swap_gb=2
elif [[ "$ram_gb" -gt 8 ]]; then
  swap_gb=8
else
  swap_gb="$ram_gb"
fi
echo "  Taille du swap choisie : ${swap_gb}G (RAM détectée: ${ram_gb}G)"
sudo mkdir -p /mnt/var/lib
sudo fallocate -l "${swap_gb}G" /mnt/var/lib/swapfile
sudo chmod 600       /mnt/var/lib/swapfile
sudo mkswap          /mnt/var/lib/swapfile
sudo swapon          /mnt/var/lib/swapfile

echo ""
echo "  [5/6] Installation de NixOS (5-15 minutes)..."
sudo nixos-install \
  --root /mnt \
  --flake "$WORK_DIR#$FLAKE_ATTR" \
  --no-root-passwd \
  --impure \
  --option "extra-experimental-features" "nix-command flakes" 2>&1 | { grep -v '^warning:' || true; }

echo ""
echo "  [6/6] Sauvegarde de la configuration..."
sudo mkdir -p /mnt/etc/nixos
sudo cp -r "$WORK_DIR" /mnt/etc/nixos/config

# Pre-creer les overrides de menu pour eviter les 11 categories au premier boot
USER_APPS="/mnt/home/user/.local/share/applications"
sudo mkdir -p "$USER_APPS"
for app in xterm yelp nm-connection-editor orca onboard bulky file-roller gnome-disk-utility gnome-disks baobab; do
  sudo tee "$USER_APPS/$app.desktop" > /dev/null <<HIDE
[Desktop Entry]
Name=$app
Type=Application
NoDisplay=true
Hidden=true
HIDE
done
sudo chown -R 1000:100 /mnt/home/user/

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║       Installation terminee!         ║"
echo "  ║       Redemarrage en cours...        ║"
echo "  ╚══════════════════════════════════════╝"
echo ""
sudo reboot
