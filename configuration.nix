{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ── Boot ────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;
  hardware.enableRedistributableFirmware = true;

  # ── Network ─────────────────────────────────────────────────
  networking.hostName          = "do2laptop";
  networking.networkmanager.enable = true;

  # ── Language & Region (French Canadian) ─────────────────────
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

  # Physical keyboard layout: QWERTY (matches ThinkPad keyboard)
  # UI and language will still be French
  services.xserver.xkb.layout  = "us";
  services.xserver.xkb.variant = "";

  # ── Desktop: GNOME ──────────────────────────────────────────
  # GNOME is the simplest, most intuitive desktop for non-tech users
  services.xserver.enable                = true;
  services.displayManager.gdm.enable    = true;
  services.desktopManager.gnome.enable  = true;

  # Auto-login: laptop boots straight to the desktop, no password screen
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user   = "utilisateur";

  # Required workaround for GNOME auto-login to work
  systemd.services."getty@tty1".enable  = false;
  systemd.services."autovt@tty1".enable = false;

  # ── Audio ───────────────────────────────────────────────────
  hardware.pulseaudio.enable = false;
  security.rtkit.enable      = true;
  services.pipewire = {
    enable       = true;
    alsa.enable  = true;
    pulse.enable = true;
  };

  # ── User ────────────────────────────────────────────────────
  users.users.utilisateur = {
    isNormalUser  = true;
    description   = "Utilisateur";
    extraGroups   = [ "networkmanager" "wheel" ];
    initialPassword = "do2projet";
  };

  # ── Swap (4GB virtual memory) ────────────────────────────────
  swapDevices = [{
    device = "/var/lib/swapfile";
    size   = 4096;
  }];

  # ── Enable Flakes ────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ── Applications ────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [

    # Web browser (auto-switches UI to French)
    firefox

    # Full office suite — opens .docx, .xlsx, .pptx files
    #   Writer  = Word equivalent
    #   Calc    = Excel equivalent
    #   Impress = PowerPoint equivalent
    libreoffice-fresh

    # Translation app (requires internet, uses Google Translate)
    dialect

    # Universal media player (videos, music, DVDs)
    vlc

    # Email client
    thunderbird

  ];

  # Remove default GNOME apps we don't need (keeps things simple and clean)
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour    # Intro tour popup (annoying for new users)
    epiphany      # GNOME's own browser (using Firefox instead)
    geary         # GNOME's own email (using Thunderbird instead)
    gnome-maps
    gnome-weather
    totem         # GNOME video player (using VLC instead)
  ];

  # ── Fonts ────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    noto-fonts           # Universal characters
    noto-fonts-cjk-sans  # Asian characters
    liberation_ttf       # Free equivalents to Arial, Times New Roman, etc.
  ];

  system.stateVersion = "24.11";
}
