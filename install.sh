#!/usr/bin/env bash
set -euo pipefail

# DO2 NixOS Install Script — by SunSinD, pour DO2 - Collège Montmorency
# Improvements: ISO-disk exclusion + cleanup trap (from greyxp1/nixos-config)

REPO_URL="https://github.com/SunSinD/Projet-DO2-NixOS.git"
FLAKE_ATTR="do2"
WORK_DIR="/tmp/do2config"

export NIX_CONFIG="experimental-features = nix-command flakes"

# ── Cleanup on exit so the script can be safely re-run ─────────────────────
cleanup() {
  sudo swapoff /mnt/swapfile 2>/dev/null || true
  sudo umount -lR /mnt       2>/dev/null || true
}
trap cleanup EXIT

echo "========================================"
echo "  DO2 - Dons d'ordinateurs, 2e vie"
echo "  Installation automatique de NixOS"
echo "========================================"
echo ""

# ── Step 0 — Cleanup previous mounts ──────────────────────────────────────
echo "Nettoyage des montages précédents..."
sudo umount -lR /mnt 2>/dev/null || true
sudo swapoff -a      2>/dev/null || true

# ── Step 1 — Clone config ──────────────────────────────────────────────────
echo "[1/5] Téléchargement de la configuration..."
rm -rf "$WORK_DIR"
git clone "$REPO_URL" "$WORK_DIR"
cd "$WORK_DIR"

# ── Step 2 — Disk selection ────────────────────────────────────────────────
echo "------------------------------------------------------------------------"
echo "Select the target disk (INTERNAL drives are usually nvme0n1 or sda):"
lsblk -dno NAME,SIZE,MODEL | grep -v "loop"
echo "------------------------------------------------------------------------"

read -p "Enter disk name (e.g., nvme0n1 or sda): " SELECTED_DISK
TARGET_DEVICE="/dev/$SELECTED_DISK"

# Safety check: Is this the USB?
if lsblk -no TRAN "$TARGET_DEVICE" | grep -q "usb"; then
    echo "ERROR: $TARGET_DEVICE appears to be a USB drive! Stay safe."
    exit 1
fi

# Exclude the disk that the live ISO is running from (borrowed from greyxp1)
ISO_SOURCE=$(findmnt -n -o SOURCE /iso 2>/dev/null || true)
ISO_DISK=""
[[ -n "$ISO_SOURCE" ]] && ISO_DISK=$(lsblk -no PKNAME "$ISO_SOURCE" 2>/dev/null || true)

mapfile -t DISK_NAMES < <(
  lsblk -dn -o NAME,TYPE -e 7 \
    | awk '$2=="disk"{print $1}' \
    | grep -v "^${ISO_DISK}$" \
  || true
)

[[ ${#DISK_NAMES[@]} -eq 0 ]] && { echo "ERREUR : Aucun disque éligible trouvé."; exit 1; }

i=0
for name in "${DISK_NAMES[@]}"; do
  SIZE=$( SIZE  "/dev/$name")
  MODEL=$(lsblk -dno MODEL "/dev/$name" 2>/dev/null || echo "Inconnu")
  echo "  [$i] /dev/$name  ($SIZE)  $MODEL"
  i=$((i+1))
done

echo ""
exec < /dev/tty
read -rp "Sur quel disque voulez-vous installer ? (Entrez le numéro) : " CHOICE
if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 0 ] || [ "$CHOICE" -ge "${#DISK_NAMES[@]}" ]; then
  echo "ERREUR : Numéro de disque invalide."
  exit 1
fi
DEV="/dev/${DISK_NAMES[$CHOICE]}"

echo ""
echo "  Disque sélectionné : $DEV"
echo ""
read -rp "ATTENTION : TOUTES LES DONNÉES SUR $DEV SERONT EFFACÉES. Confirmer ? (oui/non) : " CONFIRM

if [[ "$CONFIRM" != "oui" ]]; then
  echo "Installation annulée."
  exit 1
fi

# ── Step 3 — Partition and format with Disko ──────────────────────────────
echo ""
echo "[2/5] Partitionnement du disque..."
sed -i "s|device = \"/dev/[^\"]*\"; # DO2_DISK|device = \"$DEV\"; # DO2_DISK|" flake.nix
git add flake.nix
echo "{ }" > hardware-configuration.nix
git add hardware-configuration.nix
sudo nix --extra-experimental-features "nix-command flakes" run \
  github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --flake ".#$FLAKE_ATTR"

# ── Step 4 — Generate hardware config and lock flake ─────────────────────
echo ""
echo "[3/5] Détection du matériel..."
sudo nixos-generate-config --root /mnt --no-filesystems
sudo cp /mnt/etc/nixos/hardware-configuration.nix "$WORK_DIR/hardware-configuration.nix"
git add hardware-configuration.nix

echo "Génération du fichier de verrouillage..."
nix --extra-experimental-features "nix-command flakes" flake update
git add .
git -c user.email="do2@montmorency.qc.ca" \
    -c user.name="DO2-Installer" \
    commit -m "Local setup for $(hostname)"

# ── Step 5 — Temporary swap (for the installer only) ─────────────────────
echo ""
echo "[4/5] Configuration du swap..."
sudo fallocate -l 4G /mnt/swapfile
sudo chmod 600       /mnt/swapfile
sudo mkswap          /mnt/swapfile
sudo swapon          /mnt/swapfile

# ── Step 6 — Install ──────────────────────────────────────────────────────
echo ""
echo "[5/5] Installation de NixOS..."
sudo nixos-install \
  --root /mnt \
  --flake "$WORK_DIR#$FLAKE_ATTR" \
  --no-root-passwd \
  --impure \
  --option "extra-experimental-features" "nix-command flakes"

echo ""
echo "========================================"
echo "  Installation terminée ! Redémarrage..."
echo "========================================"
echo ""
sudo reboot
