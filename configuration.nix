{ config, pkgs, lib, inputs, device, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];
  
  # ─── Bootloader (Fixed for Legacy & UEFI) ────────────────────────────────
  boot.loader = {
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint     = "/boot";
    grub = {
      enable                = true;
      efiSupport            = true;
      efiInstallAsRemovable = true;
      device                = device; # Uses the variable passed by your installer
      forceInstall          = false;
    };
  };

  # ─── System & Compatibility ──────────────────────────────────────────────
  # Using standard kernel to avoid "Illegal Instruction" crashes on old CPUs
  boot.kernelPackages = pkgs.linuxPackages;
  services.preload.enable = true;
  hardware.enableRedistributableFirmware = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # ─── Networking & French-Canadian Locale ─────────────────────────────────
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

  # ─── Desktop Environment (GNOME) ─────────────────────────────────────────
  services.xserver = {
    enable = true;
    xkb.layout  = "us";
    wacom.enable = true;
  };

  services.displayManager = {
    gdm.enable = true;
    autoLogin.enable = true;
    autoLogin.user   = "user";
  };
  services.desktopManager.gnome.enable = true;

  # Remove GNOME default apps you don't want
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour gnome-connections epiphany geary totem gnome-music 
    gnome-characters gnome-contacts gnome-initial-setup gnome-maps 
    gnome-weather gnome-clocks gnome-software yelp
  ];

  # ─── Audio & User ────────────────────────────────────────────────────────
  security.rtkit.enable = true;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };

  users.users.user = {
    isNormalUser    = true;
    description     = "Utilisateur";
    extraGroups     = [ "networkmanager" "wheel" "video" "input" ];
    initialPassword = "pass";
  };

  # ─── System Packages & DO2 Web Apps ─────────────────────────────────────
  environment.systemPackages = with pkgs; [
    (google-chrome.override { commandLineArgs = "--password-store=basic --no-first-run"; })
    libreoffice-fresh
    vlc
    zoom-us
    yad
    fastfetch
    gnomeExtensions.dash-to-dock
    gnomeExtensions.no-overview

    # Web Apps
    (pkgs.makeDesktopItem {
      name = "microsoft-teams-web"; desktopName = "Microsoft Teams";
      exec = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://teams.microsoft.com";
      icon = "/etc/icons/teams.png"; categories = [ "Network" ];
    })
    (pkgs.makeDesktopItem {
      name = "gmail-web"; desktopName = "Gmail";
      exec = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://mail.google.com";
      icon = "/etc/icons/gmail.png"; categories = [ "Network" ];
    })
    (pkgs.makeDesktopItem {
      name = "outlook-web"; desktopName = "Outlook";
      exec = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://outlook.live.com";
      icon = "/etc/icons/outlook.png"; categories = [ "Network" ];
    })
  ];

  # ─── Assets & Wallpaper ──────────────────────────────────────────────────
  environment.etc = {
    "backgrounds/do2-wallpaper.png".source = ./assets/do2-wallpaper.png;
    "icons/teams.png".source               = ./assets/teams.png;
    "icons/gmail.png".source               = ./assets/gmail.png;
    "icons/outlook.png".source             = ./assets/outlook.png;
    "scripts/do2-welcome.sh" = {
      source = ./do2-welcome.sh;
      mode   = "0755";
    };
  };

  # ─── GNOME UI Layout ─────────────────────────────────────────────────────
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [ "dash-to-dock@micxgx.gmail.com" "no-overview@fthx" ];
        favorite-apps = [ "google-chrome.desktop" "org.gnome.Nautilus.desktop" ];
      };
      "org/gnome/desktop/background" = {
        picture-uri      = "file:///etc/backgrounds/do2-wallpaper.png";
        picture-uri-dark = "file:///etc/backgrounds/do2-wallpaper.png";
      };
    };
  }];

  # ─── System Foundations ──────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  swapDevices = [{ device = "/var/lib/swapfile"; size = 4096; }];

  # IMPORTANT: Set this to 24.11 for stability
  system.stateVersion = "24.11"; 
}
