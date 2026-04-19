# Demarrage, reseau, utilisateurs, localisation, Nix, impression, Chromebook.
{ config, pkgs, lib, device, ... }:

{
  imports = [ ./chromebook.nix ];

  # ── Chargeur d'amorçage (BIOS + UEFI) ──────────────────────────────────
  boot.loader.grub = {
    enable                = true;
    device                = device;
    efiSupport            = true;
    efiInstallAsRemovable = true;
    configurationLimit    = 1;
    theme                 = null;
    backgroundColor       = "#000000";
    splashImage           = null;
  };
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.timeout = 0;

  # Plymouth (ecran de demarrage avec logo College Montmorency)
  boot.plymouth = {
    enable = true;
    theme  = "spinner";
    logo   = ../assets/plymouth-logo.png;
    extraConfig = ''
      ShowDelay=0
      DeviceTimeout=2
    '';
  };
  boot.consoleLogLevel    = 0;
  boot.initrd.verbose     = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "vt.global_cursor_default=0"
    "udev.log_level=3"
  ];

  hardware.enableRedistributableFirmware = true;

  # ── Réseau ──────────────────────────────────────────────────────────────
  networking.hostName              = "do2laptop";
  networking.networkmanager.enable = true;

  # ── Localisation (tout en francais canadien) ────────────────────────────
  time.timeZone      = "America/Montreal";
  i18n.defaultLocale = "fr_CA.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "fr_CA.UTF-8";
    LC_IDENTIFICATION = "fr_CA.UTF-8";
    LC_MEASUREMENT    = "fr_CA.UTF-8";
    LC_MONETARY       = "fr_CA.UTF-8";
    LC_NAME           = "fr_CA.UTF-8";
    LC_NUMERIC        = "fr_CA.UTF-8";
    LC_PAPER          = "fr_CA.UTF-8";
    LC_TELEPHONE      = "fr_CA.UTF-8";
    LC_TIME           = "fr_CA.UTF-8";
  };
  console.keyMap = "cf";

  # ── Utilisateur par défaut ──────────────────────────────────────────────
  users.users.user = {
    isNormalUser    = true;
    description     = "Utilisateur";
    extraGroups     = [ "networkmanager" "wheel" "video" "input" ];
    initialPassword = "pass";
  };

  # ── Mémoire virtuelle ──────────────────────────────────────────────────
  swapDevices = [{
    device = "/var/lib/swapfile";
    size   = 4096;
  }];
  zramSwap.enable        = true;
  zramSwap.memoryPercent = 50;

  # ── Nix (flakes actives, nettoyage automatique) ────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users         = [ "root" "@wheel" ];
    auto-optimise-store   = true;
  };
  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 30d";
  };

  nixpkgs.config.allowUnfree = true;
  # Correctif pour broadcom-sta (certains vieux portables)
  nixpkgs.config.allowInsecurePredicate =
    pkg: builtins.elem (lib.getName pkg) [ "broadcom-sta" ];

  # ── Git (pour mises à jour de la config) ────────────────────────────────
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      pull.rebase        = true;
    };
  };

  # ── Impression ──────────────────────────────────────────────────────────
  services.printing.enable = true;
  services.avahi = {
    enable       = true;
    nssmdns4     = true;
    openFirewall = true;
  };

  # ── Bluetooth ───────────────────────────────────────────────────────────
  hardware.bluetooth.enable = true;

  # ── AppImage ────────────────────────────────────────────────────────────
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # ── FSTRIM (SSD) ────────────────────────────────────────────────────────
  services.fstrim.enable = true;

  # ── Commandes utilitaires ───────────────────────────────────────────────
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "rebuild" ''
      echo "Reconstruction du système DO2..."
      sudo nixos-rebuild switch --flake /etc/nixos/config#do2 "$@"
    '')
    (pkgs.writeShellScriptBin "update-do2" ''
      set -euo pipefail
      CONFIG="/etc/nixos/config"

      echo "=== Mise à jour DO2 ==="

      # Sauvegarder les fichiers propres à cette machine
      echo "[1/4] Sauvegarde de la config matérielle..."
      sudo cp "$CONFIG/hardware-configuration.nix" /tmp/hw-backup.nix
      DEVICE=$(sudo sed -n 's|.*device = "/dev/\([^"]*\)"; # DO2_DISK.*|\1|p' "$CONFIG/flake.nix")

      # Télécharger les dernières modifications
      echo "[2/4] Téléchargement des mises à jour..."
      sudo git -C "$CONFIG" fetch origin

      # Forcer la mise à jour
      echo "[3/4] Application des mises à jour..."
      sudo git -C "$CONFIG" reset --hard origin/main

      # Restaurer les fichiers propres à cette machine
      sudo cp /tmp/hw-backup.nix "$CONFIG/hardware-configuration.nix"
      if [ -n "$DEVICE" ] && [ "$DEVICE" != "sda" ]; then
        sudo sed -i 's|device = "/dev/sda"; # DO2_DISK|device = "/dev/'"$DEVICE"'"; # DO2_DISK|' "$CONFIG/flake.nix"
      fi

      # Reconstruire
      echo "[4/4] Reconstruction du système..."
      sudo nixos-rebuild switch --flake "$CONFIG#do2" "$@"

      # Relancer le setup utilisateur au prochain login
      rm -f "$HOME/.do2-setup-done"

      echo "=== Mise à jour terminée! ==="
      echo "Redémarrez pour voir les changements : sudo reboot"
    '')
  ];
}
