#!/usr/bin/env bash
set -euo pipefail

# DO2 NixOS Install Script — by SunSinD, pour DO2 - Collège Montmorency
# Disk UI: numbered list only — type 0, 1, 2, … (not device names).
# Bump when changing this file so live ISO users know they have the latest:
INSTALL_SCRIPT_REV="2026-02-09.2"

REPO_URL="https://github.com/SunSinD/Projet-DO2-NixOS.git"
FLAKE_ATTR="do2"
WORK_DIR="/tmp/do2config"

export NIX_CONFIG="experimental-features = nix-command flakes"

cleanup() {
  sudo swapoff /mnt/swapfile 2>/dev/null || true
  sudo umount -lR /mnt       2>/dev/null || true
}
trap cleanup EXIT

echo "========================================"
echo "  DO2 - Dons d'ordinateurs, 2e vie"
echo "  Installation automatique de NixOS"
echo "  (install.sh rev $INSTALL_SCRIPT_REV)"
echo "========================================"
echo ""

echo "Nettoyage des montages précédents..."
sudo umount -lR /mnt 2>/dev/null || true
sudo swapoff -a      2>/dev/null || true

echo "[1/5] Téléchargement de la configuration..."
rm -rf "$WORK_DIR"
git clone "$REPO_URL" "$WORK_DIR"
cd "$WORK_DIR"

# ── Disk list: choose by index (0, 1, 2, …) ─────────────────────────────────
echo ""
echo "------------------------------------------------------------------------"
echo "Disques détectés (le disque ISO est exclu quand c’est possible) :"
echo ""

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
  echo "ERREUR : aucun disque éligible."
  exit 1
fi

idx=0
for disk_name in "${DISK_NAMES[@]}"; do
  disk_size=$(lsblk -dno SIZE "/dev/${disk_name}" 2>/dev/null || echo "?")
  disk_model=$(lsblk -dno MODEL "/dev/${disk_name}" 2>/dev/null || echo "Inconnu")
  echo "  [$idx]  /dev/${disk_name}  (${disk_size})  ${disk_model}"
  idx=$((idx + 1))
done

echo ""
echo "Tapez UNIQUEMENT le numéro entre crochets (ex. 0 ou 1), puis Entrée."
exec < /dev/tty
read -rp "Numéro du disque cible : " CHOICE

if ! [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
  echo "ERREUR : entrez seulement un chiffre (0, 1, 2, …), pas le nom du disque."
  exit 1
fi
if [[ "$CHOICE" -lt 0 ]] || [[ "$CHOICE" -ge ${#DISK_NAMES[@]} ]]; then
  echo "ERREUR : numéro hors limite. Choix valides : 0 … $((${#DISK_NAMES[@]} - 1))."
  exit 1
fi

DEV="/dev/${DISK_NAMES[$CHOICE]}"

if lsblk -no TRAN "$DEV" 2>/dev/null | grep -q "usb"; then
  echo "ERREUR : $DEV ressemble à une clé USB. Choisissez le disque interne."
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

echo ""
echo "[2/5] Partitionnement du disque..."
sed -i "s|device = \"/dev/[^\"]*\"; # DO2_DISK|device = \"$DEV\"; # DO2_DISK|" flake.nix
git add flake.nix
echo "{ }" > hardware-configuration.nix
git add hardware-configuration.nix
sudo nix --extra-experimental-features "nix-command flakes" run \
  github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --yes-wipe-all-disks \
  --flake ".#$FLAKE_ATTR"

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

echo ""
echo "[4/5] Configuration du swap..."
sudo fallocate -l 4G /mnt/swapfile
sudo chmod 600       /mnt/swapfile
sudo mkswap          /mnt/swapfile
sudo swapon          /mnt/swapfile

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
