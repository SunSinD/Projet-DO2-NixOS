#!/usr/bin/env bash
set -euo pipefail

WORK_DIR=$(cd -- "$(dirname -- "$0")/.." && pwd)
source "$WORK_DIR/scripts/do2-disk.sh"
TARGET=/mnt
SWAPFILE="$TARGET/var/lib/swapfile"
MOUNT_STARTED=false
SWAP_ACTIVE=false

export NIX_CONFIG="${NIX_CONFIG:-}
extra-experimental-features = nix-command flakes"

if [[ $EUID -ne 0 ]] || ! command -v nixos-install >/dev/null; then
  echo "Démarrez sur la clé NixOS minimale et lancez l'installation avec sudo." >&2
  exit 1
fi

exec < /dev/tty
iso_source=$(findmnt -nro SOURCE --mountpoint /iso) || {
  echo "Clé d'installation NixOS introuvable sur /iso." >&2
  exit 1
}
iso_disks=$(lsblk -snrpo NAME "$iso_source") || {
  echo "Impossible d'identifier la clé. Redémarrez sur l'entrée normale du menu NixOS." >&2
  exit 1
}

exec 9>/run/lock/do2-install.lock
flock -n 9 || { echo "Une installation DO2 est déjà en cours." >&2; exit 1; }

target_is_free() {
  local mounts
  mounts=$(findmnt -rn -o TARGET) || return 1
  if grep -Eq '^/mnt(/|$)' <<< "$mounts"; then
    echo "Un système de fichiers est déjà monté dans /mnt." >&2
    return 1
  fi
}

disk_is_available() {
  local disk=$1 mounts transport
  mounts=$(lsblk -nrpo MOUNTPOINTS "$disk") || return 1
  transport=$(lsblk -dnro TRAN "$disk") || return 1
  [[ -z "$mounts" && "$transport" != usb ]] &&
    ! grep -Fxq -- "$disk" <<< "$iso_disks"
}

unmount_target() {
  if $SWAP_ACTIVE; then
    swapoff "$SWAPFILE" || return 1
    SWAP_ACTIVE=false
  fi
  if $MOUNT_STARTED && mountpoint -q "$TARGET"; then
    umount -R "$TARGET" || return 1
  fi
  MOUNT_STARTED=false
}

trap 'unmount_target || echo "Impossible de démonter /mnt." >&2' EXIT

echo "Installation DO2 pour le Collège Montmorency"
target_is_free
disks=()
ids=()
while read -r disk kind removable readonly id; do
  if [[ "$kind" == disk && "$removable" == 0 && "$readonly" == 0 && "$disk" != /dev/mmcblk*boot* ]] && disk_is_available "$disk"; then
    printf '  [%s] %s\n' "${#disks[@]}" "$(lsblk -dno PATH,SIZE,MODEL "$disk")"
    disks+=("$disk")
    ids+=("$id")
  fi
done < <(lsblk -dnrpo NAME,TYPE,RM,RO,MAJ:MIN)

if [[ ${#disks[@]} -eq 0 ]]; then
  echo "Aucun disque interne libre détecté." >&2
  exit 1
fi

read -rp "Choisissez un numéro de disque : " choice
if [[ ! "$choice" =~ ^(0|[1-9][0-9]{0,3})$ ]] || (( choice >= ${#disks[@]} )); then
  echo "Choix invalide." >&2
  exit 1
fi
device=${disks[choice]}
boot_disk=$(stable_disk_path "$device")

if (( $(lsblk -bdnro SIZE "$device") < 32000000000 )); then
  echo "Le disque doit avoir au moins 32 Go." >&2
  exit 1
fi

printf '\nToutes les données sur %s seront effacées.\n' "$device"
read -rp "Pour confirmer, tapez $device : " confirm
if [[ "$confirm" != "$device" ]]; then
  echo "Installation annulée."
  exit 0
fi

cd "$WORK_DIR"
echo "[1/5] Vérification de la configuration et des téléchargements…"
nix eval --impure --no-write-lock-file --raw "path:.#nixosConfigurations.do2.config.system.build.toplevel.drvPath" >/dev/null
nix build --no-link --no-write-lock-file "path:.#disko" "path:.#app-downloads"

target_is_free
if [[ "$(lsblk -dnro MAJ:MIN "$device")" != "${ids[choice]}" || ! "$boot_disk" -ef "$device" ]] || ! disk_is_available "$device"; then
  echo "Le disque sélectionné a changé ou est utilisé." >&2
  exit 1
fi
sed -i "s|device = \"/dev/sda\"; # DO2_DISK|device = \"$boot_disk\"; # DO2_DISK|" flake.nix

echo "[2/5] Partitionnement de $device…"
MOUNT_STARTED=true
nix run --no-write-lock-file "path:.#disko" -- \
  --mode destroy,format,mount --yes-wipe-all-disks --flake "path:.#do2"
mountpoint -q "$TARGET" || { echo "/mnt n'est pas monté." >&2; exit 1; }
mountpoint -q "$TARGET/boot" || { echo "/mnt/boot n'est pas monté." >&2; exit 1; }

echo "[3/5] Détection du matériel et préparation du swap…"
nixos-generate-config --root "$TARGET" --no-filesystems
cp "$TARGET/etc/nixos/hardware-configuration.nix" hardware-configuration.nix

swap_gb=$(awk '/MemTotal/ { n = int($2 / 1048576 + 0.5); print n < 2 ? 2 : (n > 8 ? 8 : n) }' /proc/meminfo)
install -d "$TARGET/var/lib"
install -m 600 /dev/null "$SWAPFILE"
fallocate -l "${swap_gb}G" "$SWAPFILE"
mkswap "$SWAPFILE"
swapon "$SWAPFILE"
SWAP_ACTIVE=true

echo "[4/5] Installation de NixOS…"
nixos-install --root "$TARGET" --flake "path:$WORK_DIR#do2" --no-root-passwd --no-channel-copy --impure

echo "[5/5] Sauvegarde de la configuration et création du mot de passe…"
cp -a "$WORK_DIR" "$TARGET/etc/nixos/config"
echo "Choisissez le mot de passe du compte user dans la disposition actuelle du clavier."
until nixos-enter --root "$TARGET" -c '/nix/var/nix/profiles/system/sw/bin/passwd user'; do
  echo "Le mot de passe n'a pas été défini. Réessayez ou faites Ctrl+C pour arrêter." >&2
done

unmount_target
echo "Installation terminée. Lancez sudo reboot et retirez la clé USB au redémarrage."
