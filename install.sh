#!/usr/bin/env bash
set -euo pipefail

# DO2 NixOS Install Script — by SunSinD, pour DO2 - Collège Montmorency

REPO_URL="https://github.com/SunSinD/Projet-DO2-NixOS.git"
FLAKE_ATTR="do2"

echo "========================================"
echo "  DO2 - Dons d'ordinateurs, 2e vie"
echo "  Installation automatique de NixOS"
echo "========================================"
echo ""

# Step 0 — Cleanup previous attempts to fix "target busy"
echo "Nettoyage des montages précédents..."
sudo umount -lR /mnt 2>/dev/null || true
sudo swapoff -a 2>/dev/null || true

# Step 1 — Clone the config
echo "[1/5] Téléchargement de la configuration..."
rm -rf /tmp/do2config
git clone "$REPO_URL" /tmp/do2config
cd /tmp/do2config

# Step 2 — Disk selection
echo ""
echo "------------------------------------------------------------------------"
echo "Disques physiques détectés :"
echo ""

mapfile -t DISK_NAMES < <(lsblk -dn -o NAME,TYPE,MOUNTPOINTS | grep disk | grep -v '/iso' | awk '{print $1}')

i=0
for name in "${DISK_NAMES[@]}"; do
    SIZE=$(lsblk -dno SIZE "/dev/$name")
    MODEL=$(lsblk -dno MODEL "/dev/$name" 2>/dev/null || echo "Inconnu")
    echo "  [$i] /dev/$name  ($SIZE)  $MODEL"
    i=$((i+1))
done

echo ""
exec < /dev/tty
read -rp "Sur quel disque voulez-vous installer ? (Entrez le numéro) : " CHOICE
DEV="/dev/${DISK_NAMES[$CHOICE]}"

echo ""
echo "  Disque sélectionné : $DEV"
echo ""
read -rp "ATTENTION : TOUTES LES DONNÉES SUR $DEV SERONT EFFACÉES. Confirmer ? (oui/non) : " CONFIRM

if [[ "$CONFIRM" != "oui" ]]; then
    echo "Installation annulée."
    exit 1
fi

# Step 3 — Partition and format with Disko
echo ""
echo "[2/5] Partitionnement du disque..."
sed -i "s|device = \".*\"; # Default|device = \"$DEV\"; # Default|" flake.nix
sed -i "s|device = \".*\";|device = \"$DEV\";|" disko-config.nix

sudo nix --experimental-features "nix-command flakes" run \
    github:nix-community/disko/latest -- \
    --mode destroy,format,mount \
    --yes-wipe-all-disks \
    ./disko-config.nix

# Step 4 — Generate hardware config
echo ""
echo "[3/5] Détection du matériel..."
sudo nixos-generate-config --root /mnt --no-filesystems
sudo cp /mnt/etc/nixos/hardware-configuration.nix /tmp/do2config/hardware-configuration.nix

echo "Génération du fichier de verrouillage (flake.lock)..."
nix flake update --commit-lock-file 2>/dev/null || nix flake update

git add .
git -c user.email="do2@montmorency.qc.ca" -c user.name="DO2-Installer" commit -m "Local hardware and lock config"

# Step 5 — Swap
echo ""
echo "[4/5] Configuration du swap..."
sudo fallocate -l 4G /mnt/swapfile
sudo chmod 600 /mnt/swapfile
sudo mkswap /mnt/swapfile
sudo swapon /mnt/swapfile

# Step 6 — Install
echo ""
echo "[5/5] Installation de NixOS..."
sudo nixos-install --root /mnt --flake "/tmp/do2config#$FLAKE_ATTR" --no-root-passwd

echo ""
echo "========================================"
echo "  Installation terminée !"
echo "========================================"
echo ""
sudo reboot
