#!/usr/bin/env bash
set -euo pipefail

# DO2 NixOS Install Script — by SunSinD, pour DO2 - Collège Montmorency

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

echo "------------------------------------------------------------------------"
echo "Sélectionnez le disque cible :"
i=0
for name in "${DISK_NAMES[@]}"; do
  SIZE=$(lsblk -dno SIZE "/dev/$name")
  MODEL=$(lsblk -dno MODEL "/dev/$name" 2>/dev/null || echo "Inconnu")
  echo "  [$i] /dev/$name  ($SIZE)  $MODEL"
  i=$((i+1))
done
echo "------------------------------------------------------------------------"

exec < /dev/tty
read -rp "Entrez le numéro du disque : " CHOICE

# Validate input
if [[ -z "${DISK_NAMES[$CHOICE]+x}" ]]; then
  echo "ERREUR : Choix invalide."
  exit 1
fi

DEV="/dev/${DISK_NAMES[$CHOICE]}"

# Safety check: Is this a USB?
if lsblk -no TRAN "$DEV" | grep -q "usb"; then
    echo "ERREUR : $DEV semble être une clé USB ! Installation annulée par sécurité."
    exit 1
fi

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
sed -i "s|device = \".*\"; # Default|device = \"$DEV\"; # Default|" flake.nix
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
    commit -m "Configuration locale pour $(hostname)"

# ── Step 5 — Temporary swap (for the installer only) ─────────────────────
echo ""
echo "[4/5] Configuration du swap temporaire..."
sudo fallocate -l 4G /mnt/swapfile
sudo chmod 600       /mnt/swapfile
sudo mkswap          /mnt/swapfile > /dev/null
sudo swapon          /mnt/swapfile

# ── Step 6 — Install ──────────────────────────────────────────────────────
echo ""
echo "[5/5] Installation de NixOS..."
sudo nixos-install \
  --root /mnt \
  --flake "$WORK_DIR#$FLAKE_ATTR" \
  --no-root-passwd \
  --impure \
  --option "extra-experimental-features" "nix-command flakes" \
  --option substituters "https://cache.nixos.org https://nix-community.cachix.org" \
  --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="

echo ""
echo "========================================"
echo "  Installation terminée ! Redémarrage..."
echo "========================================"
echo ""
sudo reboot
