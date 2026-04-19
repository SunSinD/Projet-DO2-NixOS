#!/usr/bin/env bash
set -euo pipefail

# DO2 - installateur complet (telecharge par install.sh).
# Menu de disques : CHIFFRES UNIQUEMENT - 0, 1, 2, ...
INSTALL_SCRIPT_REV="2026-04-18.1"

REPO_URL="https://github.com/SunSinD/Projet-DO2-Nixbook.git"
FLAKE_ATTR="do2"
WORK_DIR="/tmp/do2config"

export NIX_CONFIG="experimental-features = nix-command flakes"

cleanup() {
  sudo swapoff /mnt/var/lib/swapfile 2>/dev/null || true
  sudo umount -lR /mnt               2>/dev/null || true
}
trap cleanup EXIT

echo "========================================"
echo "  DO2 - Dons d'ordinateurs, 2e vie"
echo "  Installation automatique de NixOS"
echo "  (do2-install.sh rev $INSTALL_SCRIPT_REV)"
echo "========================================"
echo ""

echo "Nettoyage des montages précédents..."
sudo umount -lR /mnt 2>/dev/null || true
sudo swapoff -a      2>/dev/null || true

echo "[1/6] Téléchargement de la configuration..."
rm -rf "$WORK_DIR"
git clone "$REPO_URL" "$WORK_DIR"
cd "$WORK_DIR"

# ── Liste des disques : choisir par numéro (0, 1, 2, …) ─────────────────
echo ""
echo "------------------------------------------------------------------------"
echo "  >>> DISQUE : tapez SEULEMENT le chiffre 0 ou 1 (ou 2, …). <<<"
echo "  >>> PAS le nom du disque (nvme0n1, sda, etc.).              <<<"
echo "------------------------------------------------------------------------"
echo "Disques détectés (disque ISO exclu si possible) :"
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
echo "Entrez SEULEMENT le numéro entre crochets :"
exec < /dev/tty
read -rp "Numéro du disque (0, 1, …) : " CHOICE

if ! [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
  echo "ERREUR : utilisez un chiffre comme 0 ou 1, pas le nom du disque."
  exit 1
fi
if [[ "$CHOICE" -lt 0 ]] || [[ "$CHOICE" -ge ${#DISK_NAMES[@]} ]]; then
  echo "ERREUR : hors limites. Valide : 0 … $((${#DISK_NAMES[@]} - 1))."
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
echo "[2/6] Partitionnement du disque..."
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
echo "[3/6] Détection du matériel..."
sudo nixos-generate-config --root /mnt --no-filesystems
sudo cp /mnt/etc/nixos/hardware-configuration.nix "$WORK_DIR/hardware-configuration.nix"
git add hardware-configuration.nix

echo "Génération du fichier de verrouillage..."
nix --extra-experimental-features "nix-command flakes" flake update
git add .
git -c user.email="do2@montmorency.qc.ca" \
    -c user.name="DO2-Installer" \
    commit -m "Configuration locale pour $(hostname)"

echo ""
echo "[4/6] Configuration du swap..."
sudo mkdir -p /mnt/var/lib
sudo fallocate -l 4G /mnt/var/lib/swapfile
sudo chmod 600       /mnt/var/lib/swapfile
sudo mkswap          /mnt/var/lib/swapfile
sudo swapon          /mnt/var/lib/swapfile

echo ""
echo "[5/6] Installation de NixOS (cela peut prendre 15-30 minutes)..."
sudo nixos-install \
  --root /mnt \
  --flake "$WORK_DIR#$FLAKE_ATTR" \
  --no-root-passwd \
  --impure \
  --option "extra-experimental-features" "nix-command flakes"

echo ""
echo "[6/6] Sauvegarde permanente de la config..."
sudo mkdir -p /mnt/etc/nixos
sudo cp -r "$WORK_DIR" /mnt/etc/nixos/config

echo ""
echo "========================================"
echo "  Installation terminée !"
echo "  L'ordinateur va redémarrer..."
echo "========================================"
echo ""
sleep 3
sudo reboot
