{ config, pkgs, lib, inputs, device, ... }:

{
  imports = [ ./hardware-configuration.nix ];

# ─── System & Performance ────────────────────────────────────────────────
  # Using the default LTS kernel for maximum hardware compatibility on old laptops
  # We will rely on preload for responsiveness instead of CPU-specific kernels
  services.preload.enable = true;

  # Firmware and hardware support
  hardware.enableRedistributableFirmware = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # ─── Bootloader (GRUB) ───────────────────────────────────────────────────
  boot.loader = {
    efi.canTouchEfiVariables = true; 
    efi.efiSysMountPoint     = "/boot";
    grub = {
      enable                = true;
      efiSupport            = true;
      efiInstallAsRemovable = true;
      device                = device; # Changed back to variable for Legacy BIOS support
      forceInstall          = false;
    };
  };

  # ─── Networking & Localization ───────────────────────────────────────────
  networking.hostName              = "do2laptop";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Montreal";
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
    xkb.variant = "";
    wacom.enable = true; # Touchscreen/Pen support
  };

  services.displayManager = {
    gdm.enable = true;
    autoLogin.enable = true;
    autoLogin.user   = "user";
  };
  services.desktopManager.gnome.enable = true;

  # Required fix for GNOME auto-login
  systemd.services."getty@tty1".enable  = false;
  systemd.services."autovt@tty1".enable = false;

  # Remove default GNOME bloatware
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
    vlc              # Replaced mpv with vlc
    zoom-us
    yad              # Powers the welcome popup
    bat
    fastfetch
    tree
    curl
    gnomeExtensions.dash-to-dock
    gnomeExtensions.no-overview

    # Web Apps Desktop Items
    (pkgs.makeDesktopItem {
      name = "microsoft-teams-web"; desktopName = "Microsoft Teams";
      exec = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://teams.microsoft.com";
      icon = "/etc/icons/teams.png"; categories = [ "Network" "InstantMessaging" ];
    })
    (pkgs.makeDesktopItem {
      name = "gmail-web"; desktopName = "Gmail";
      exec = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://mail.google.com";
      icon = "/etc/icons/gmail.png"; categories = [ "Network" "Email" ];
    })
    (pkgs.makeDesktopItem {
      name = "google-meet-web"; desktopName = "Google Meet";
      exec = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://meet.google.com";
      icon = "/etc/icons/meet.png"; categories = [ "Network" "VideoConference" ];
    })
    (pkgs.makeDesktopItem {
      name = "outlook-web"; desktopName = "Outlook";
      exec = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://outlook.live.com";
      icon = "/etc/icons/outlook.png"; categories = [ "Network" "Email" ];
    })
    (pkgs.makeDesktopItem {
      name = "excalidraw-web"; desktopName = "Excalidraw";
      exec = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://excalidraw.com";
      icon = "/etc/icons/excalidraw.png"; categories = [ "Graphics" ];
      comment = "Tableau de dessin collaboratif (web)";
    })
  ];

  # ─── Static Assets & Welcome Script ──────────────────────────────────────
  environment.etc = {
    "backgrounds/do2-wallpaper.png".source = ./assets/do2-wallpaper.png;
    "icons/teams.png".source               = ./assets/teams.png;
    "icons/gmail.png".source               = ./assets/gmail.png;
    "icons/meet.png".source                = ./assets/meet.png;
    "icons/outlook.png".source             = ./assets/outlook.png;
    "icons/excalidraw.png".source          = ./assets/excalidraw.png;
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
      NoDisplay=true
    '';
  };

  # ─── GNOME dconf Settings ────────────────────────────────────────────────
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [ "dash-to-dock@micxgx.gmail.com" "no-overview@fthx" ];
        favorite-apps = [ "google-chrome.desktop" "org.gnome.Nautilus.desktop" ];
      };
      "org/gnome/shell/extensions/dash-to-dock" = {
        dock-position = "BOTTOM";
        show-apps-at-top = false;
        extend-height = false;
        show-trash = false;
        show-mounts = false;
      };
      "org/gnome/desktop/app-folders" = {
        folder-children = [ "LibreOffice" "Communication" "Medias" ];
      };
      "org/gnome/desktop/app-folders/folders/LibreOffice" = {
        name = "LibreOffice";
        apps = [ "libreoffice-startcenter.desktop" "libreoffice-writer.desktop" "libreoffice-calc.desktop" "libreoffice-impress.desktop" ];
      };
      "org/gnome/desktop/app-folders/folders/Communication" = {
        name = "Communication";
        apps = [ "gmail-web.desktop" "microsoft-teams-web.desktop" "google-meet-web.desktop" "outlook-web.desktop" "Zoom.desktop" ];
      };
      "org/gnome/desktop/app-folders/folders/Medias" = {
        name = "Médias";
        apps = [ "vlc.desktop" "excalidraw-web.desktop" ];
      };
      "org/gnome/mutter" = { dynamic-workspaces = false; };
      "org/gnome/desktop/wm/preferences" = { num-workspaces = lib.gvariant.mkInt32 1; };
      "org/gnome/desktop/background" = {
        picture-uri      = "file:///etc/backgrounds/do2-wallpaper.png";
        picture-uri-dark = "file:///etc/backgrounds/do2-wallpaper.png";
      };
    };
  }];

  # ─── System Foundations ──────────────────────────────────────────────────
  fonts.packages = with pkgs; [ noto-fonts noto-fonts-cjk-sans liberation_ttf ];
  
  swapDevices = [{ device = "/var/lib/swapfile"; size = 4096; }];
  
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];
  };
  nixpkgs.config.allowUnfree = true;

  programs.git = {
    enable = true;
    config = { init.defaultBranch = "main"; pull.rebase = true; };
  };

  system.stateVersion = "25.11"; # Ensure this matches your original flake
}
