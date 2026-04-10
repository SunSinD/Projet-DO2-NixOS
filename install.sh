#!/usr/bin/env bash
set -euo pipefail

# DO2 NixOS Install Script — by SunSinD, pour DO2 - Collège Montmorency

REPO_URL="https://github.com/SunSinD/Projet-DO2-NixOS.git"
FLAKE_ATTR="do2"

# FIX: This enables experimental features for the whole script session
export NIX_CONFIG="experimental-features = nix-command flakes"

echo "========================================"
echo "  DO2 - Dons d'ordinateurs, 2e vie"
echo "  Installation automatique de NixOS"
echo "========================================"
echo ""

# Step 0 — Cleanup
echo "Nettoyage des montages précédents..."
sudo umount -lR /mnt 2>/dev/null || true
sudo swapoff -a 2>/dev/null || true

# Step 1 — Clone
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

sudo nix --extra-experimental-features "nix-command flakes" run \
    github:nix-community/disko/latest -- \
    --mode destroy,format,mount \
    --yes-wipe-all-disks \
    ./disko-config.nix

# Step 4 — Generate hardware config and lock file
echo ""
echo "[3/5] Détection du matériel..."
sudo nixos-generate-config --root /mnt --no-filesystems
sudo cp /mnt/etc/nixos/hardware-configuration.nix /tmp/do2config/hardware-configuration.nix

git add hardware-configuration.nix 

echo "Génération du fichier de verrouillage..."
nix --extra-experimental-features "nix-command flakes" flake update

git add .
git -c user.email="do2@montmorency.qc.ca" -c user.name="DO2-Installer" commit -m "Local setup for $(hostname)"

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
sudo nixos-install --root /mnt --flake "/tmp/do2config#$FLAKE_ATTR" --no-root-passwd \
    --impure \
    --option "extra-experimental-features" "nix-command flakes"

echo ""
echo "========================================"
echo "  Installation terminée ! Redémarrage..."
echo "========================================"
echo ""
sudo reboot
