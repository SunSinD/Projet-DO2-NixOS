# Demarrage, reseau, utilisateurs, localisation, Nix, impression, Chromebook.
{ pkgs, lib, live, ... }:

{
  # ── Chargeur d'amorçage (BIOS + UEFI) ──────────────────────────────────
  boot.loader.grub = {
    enable                = true;
    efiSupport            = true;
    efiInstallAsRemovable = true;
    configurationLimit    = 5;
    theme                 = null;
    backgroundColor       = "#000000";
    splashImage           = null;
  };
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.timeout = 3;

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
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "vt.global_cursor_default=0"
    "udev.log_level=3"
    "vt.handoff=7"
  ];

  hardware.enableRedistributableFirmware = true;

  # ── Réseau ──────────────────────────────────────────────────────────────
  networking.hostName              = "do2laptop";
  networking.networkmanager.enable = true;

  # ── Localisation (tout en francais canadien) ────────────────────────────
  time.timeZone      = "America/Toronto";
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
  users.users = lib.optionalAttrs (!live) {
    user = {
      isNormalUser = true;
      description  = "Utilisateur";
      extraGroups  = [ "networkmanager" "wheel" "video" "input" ];
    };
  };

  # ── Mémoire virtuelle ──────────────────────────────────────────────────
  swapDevices = [{
    device = "/var/lib/swapfile";
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

  nixpkgs.config = {
    allowUnfree = true;
  };

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
  services.packagekit.enable = true;
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
  environment.systemPackages = lib.optionals (!live) [
    (pkgs.writeShellScriptBin "rebuild" ''
      echo "Reconstruction du système DO2..."
      sudo flock -n /run/lock/do2-rebuild.lock nixos-rebuild switch --flake path:/etc/nixos/config#do2 --impure "$@"
    '')
    (let
      updater = pkgs.writeShellScript "do2-update" (
        builtins.readFile ../scripts/do2-hardware.sh
        + builtins.readFile ../scripts/do2-update.sh
      );
    in pkgs.writeShellScriptBin "update-do2" ''
      exec sudo ${updater} "$@"
    '')
    (pkgs.writeShellScriptBin "do2-japanese-keyboard" ''
      exec /etc/do2/do2-japanese-keyboard.sh "$@"
    '')
  ];
}
