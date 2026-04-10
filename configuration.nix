{ config, pkgs, inputs, device, ... }: 

{
  imports = [ ./hardware-configuration.nix ];

boot.loader = let
    isUEFI = builtins.pathExists /sys/class/efivars;
  in {
    efi.canTouchEfiVariables = isUEFI;
    efi.efiSysMountPoint     = "/boot";
    systemd-boot.enable      = isUEFI;
    grub = {
      enable     = !isUEFI;
      efiSupport = false;
    };
  };

  # Firmware support for hardware (wifi cards, etc.)
  hardware.enableRedistributableFirmware = true;

  # Network
  networking.hostName              = "do2laptop";
  networking.networkmanager.enable = true;

  # French Canadian locale and timezone
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

  # Physical keyboard layout matches ThinkPad keys (QWERTY)
  services.xserver.xkb.layout  = "us";
  services.xserver.xkb.variant = "";

  # GNOME desktop — simplest UI for non-technical users
  services.xserver.enable               = true;
  services.displayManager.gdm.enable    = true;
  services.desktopManager.gnome.enable  = true;

  # Auto-login: boots straight to desktop, no password screen
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user   = "user";

  # Required fix for GNOME auto-login
  systemd.services."getty@tty1".enable  = false;
  systemd.services."autovt@tty1".enable = false;

  # Enable sound with pipewire (modern fix)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Touchscreen and touchpad support
  services.libinput.enable = true;
  services.xserver.wacom.enable = true; 

  # Main user account
  users.users.user = {
    isNormalUser  = true;
    description   = "Utilisateur";
    extraGroups   = [ "networkmanager" "wheel" "video" "input" ];
    initialPassword = "pass";
  };

  # Swap — 4GB virtual memory
  swapDevices = [{
    device = "/var/lib/swapfile";
    size   = 4096;
  }];

  # Fixes "download buffer is full" and enables Flakes globally
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    download-buffer-size = 134217728; # 128MB
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    google-chrome
    libreoffice-fresh
    dialect
    vlc
    thunderbird
    (pkgs.makeDesktopItem {
      name        = "microsoft-teams-web";
      desktopName = "Microsoft Teams";
      exec        = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://teams.microsoft.com";
      icon        = "google-chrome";
      categories  = [ "Network" "InstantMessaging" ];
      comment     = "Microsoft Teams (web)";
    })
  ];

  environment.gnome.excludePackages = with pkgs; [ gnome-tour ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    liberation_ttf
  ];

  system.stateVersion = "25.11";
}
