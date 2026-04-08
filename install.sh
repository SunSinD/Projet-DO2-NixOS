#!/usr/bin/env bash
set -euo pipefail

# ── DO2 NixOS Install Script ────────────────────────────────────
# Based on greyxp1/nixos-config, adapted for DO2 - Collège Montmorency
#
# Run with:
#   sudo bash <(curl -sL https://raw.githubusercontent.com/SunSinD/NixOS-Config/main/install.sh)
# ───────────────────────────────────────────────────────────────

REPO_URL="https://github.com/SunSinD/NixOS-Config.git"
FLAKE_ATTR="do2laptop"

# ── Detect disk automatically ───────────────────────────────────
DISK=$(lsblk -dn -o NAME,TYPE | grep disk | head -n1 | awk '{print "/dev/" $1}')

echo "========================================"
echo "  DO2 - Dons d'ordinateurs, 2e vie"
echo "  NixOS Automated Install"
echo "========================================"
echo ""
echo "Detected disk: $DISK"
echo ""
echo "Available disks:"
lsblk -d -o NAME,SIZE,MODEL | grep -v loop
echo ""
read -rp "Use $DISK? Press Enter to confirm, or type a different disk (e.g. /dev/nvme0n1): " DISK_INPUT

if [[ -n "$DISK_INPUT" ]]; then
  DISK="$DISK_INPUT"
fi

echo ""
echo "WARNING: ALL DATA ON $DISK WILL BE ERASED."
read -rp "Type 'yes' to continue: " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborted."
  exit 1
fi

# ── Step 1: Clone the config repo ──────────────────────────────
echo ""
echo "[1/5] Cloning DO2 config from GitHub..."
rm -rf /tmp/do2config
git clone "$REPO_URL" /tmp/do2config
cd /tmp/do2config

# ── Step 2: Partition and format the disk with Disko ───────────
echo ""
echo "[2/5] Partitioning disk with Disko..."
sudo nix --experimental-features "nix-command flakes" run \
  github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --yes-wipe-all-disks \
  ./disko-config.nix \
  --argstr device "$DISK"

# ── Step 3: Generate hardware config for this specific laptop ──
echo ""
echo "[3/5] Detecting hardware configuration..."
sudo nixos-generate-config --root /mnt --no-filesystems
# Copy the generated hardware config into our repo so the flake can find it
sudo cp /mnt/etc/nixos/hardware-configuration.nix /tmp/do2config/hardware-configuration.nix

# ── Step 4: Set up swap ─────────────────────────────────────────
echo ""
echo "[4/5] Setting up swap..."
sudo fallocate -l 4G /mnt/swapfile
sudo chmod 600 /mnt/swapfile
sudo mkswap /mnt/swapfile
sudo swapon /mnt/swapfile

# ── Step 5: Install NixOS ───────────────────────────────────────
echo ""
echo "[5/5] Installing NixOS... (this takes 10-30 min depending on internet)"
sudo nixos-install --root /mnt --flake "/tmp/do2config#$FLAKE_ATTR" --no-root-passwd

echo ""
echo "========================================"
echo "  Installation complete!"
echo ""
echo "  Login: utilisateur"
echo "  Password: do2projet"
echo ""
echo "  The laptop auto-logs in on boot."
echo "========================================"
echo ""
sudo reboot
