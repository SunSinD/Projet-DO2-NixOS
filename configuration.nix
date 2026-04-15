{ config, pkgs, lib, inputs, device ? "nodev", ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ─── System & Compatibility ─────────────────────────────────────────────
  boot.kernelPackages = pkgs.linuxPackages;
  services.preload.enable = true;
  hardware.enableRedistributableFirmware = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # ─── Universal Bootloader (GRUB) ────────────────────────────────────────
  boot.loader = {
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint     = "/boot";
    grub = {
      enable                = true;
      efiSupport            = true;
      efiInstallAsRemovable = true;
      # This uses the device passed by the installer, or "nodev" if EFI
      device                = device; 
      forceInstall          = false;
    };
  };

  # ─── Networking & Localization ───────────────────────────────────────────
  networking.hostName              = "do2laptop";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Montreal";
  i18n.defaultLocale = "fr_CA.UTF-8";

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

  # Fix for GNOME auto-login
  systemd.services."getty@tty1".enable  = false;
  systemd.services."autovt@tty1".enable = false;

  # Remove default GNOME bloat
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour gnome-connections epiphany geary totem gnome-music 
    gnome-characters gnome-contacts gnome-initial-setup gnome-maps 
    gnome-weather gnome-clocks gnome-software yelp
  ];

  # ─── Audio & Input ───────────────────────────────────────────────────────
  security.rtkit.enable = true;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };
  services.libinput.enable = true;

  # ─── User Account ────────────────────────────────────────────────────────
  users.users.user = {
    isNormalUser    = true;
    description     = "Utilisateur";
    extraGroups     = [ "networkmanager" "wheel" "video" "input" ];
    initialPassword = "pass";
  };

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm-autologin.enableGnomeKeyring = true;

  # ─── System Packages & Web Apps ──────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    (google-chrome.override { commandLineArgs = "--password-store=basic --no-first-run --no-default-browser-check"; })
    libreoffice-fresh
    dialect
    vlc
    zoom-us
    yad
    fastfetch
    gnomeExtensions.dash-to-dock
    gnomeExtensions.no-overview

    # Web Apps Desktop Items
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
  ];

  # ─── Static Assets & Welcome Script ──────────────────────────────────────
  environment.etc = {
    "backgrounds/do2-wallpaper.png".source = ./assets/do2-wallpaper.png;
    "icons/teams.png".source               = ./assets/teams.png;
    "icons/gmail.png".source               = ./assets/gmail.png;
    "scripts/do2-welcome.sh" = {
      source = ./do2-welcome.sh;
      mode   = "0755";
    };
    "xdg/autostart/do2-welcome.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=DO2 Bienvenue
      Exec=/etc/scripts/do2-welcome.sh
      Terminal=false
      X-GNOME-Autostart-enabled=true
    '';
  };

  # ─── GNOME UI Settings ──────────────────────────────────────────────────
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

  # ─── Foundations ─────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [ noto-fonts liberation_ttf ];
  swapDevices = [{ device = "/var/lib/swapfile"; size = 4096; }];
  
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];
  };
  nixpkgs.config.allowUnfree = true;

  # Make sure this matches the version in your flake.nix (24.11 is recommended)
  system.stateVersion = "24.11"; 
}
