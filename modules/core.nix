# Boot, firmware, networking, users, swap, Nix store tuning.
{ config, pkgs, lib, device, ... }:

{
  boot.loader = {
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint     = "/boot";
    systemd-boot.enable      = true;
    timeout                  = 0;
  };

  hardware.enableRedistributableFirmware = true;

  networking.hostName              = "do2laptop";
  networking.networkmanager.enable = true;

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

  users.users.user = {
    isNormalUser    = true;
    description     = "Utilisateur";
    extraGroups     = [ "networkmanager" "wheel" "video" "input" ];
    initialPassword = "pass";
  };

  swapDevices = [{
    device = "/var/lib/swapfile";
    size   = 4096;
  }];

  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;

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

  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      pull.rebase        = true;
    };
  };

  services.fstrim.enable = true;

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "rebuild" ''
      sudo bash -c "cd /etc/nixos/config && git fetch origin && git reset --hard origin/main && nixos-rebuild switch --flake .#do2 && sudo -u user DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus dconf write /org/gnome/shell/favorite-apps \"['google-chrome.desktop', 'microsoft-teams-web.desktop', 'outlook-web.desktop', 'libreoffice-calc.desktop', 'libreoffice-writer.desktop', 'org.gnome.Nautilus.desktop']\" && sudo -u user DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus dconf write /org/gnome/desktop/app-folders/folder-children \"['LibreOffice', 'Communication', 'Médias', 'Internet', 'Outils']\""
    '')
  ];
}
