{ config, pkgs, lib, inputs, device, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];
  
  boot.loader = {
    efi.canTouchEfiVariables = false;
    efi.efiSysMountPoint     = "/boot";
    grub = {
      enable                = true;
      efiSupport            = true;
      efiInstallAsRemovable = true;
      device                = device;
      forceInstall          = false;
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
  services.xserver.enable              = true;
  services.displayManager.gdm.enable   = true;
  services.desktopManager.gnome.enable = true;

  # Auto-login: boots straight to desktop, no password screen
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user   = "user";

  # Required fix for GNOME auto-login
  systemd.services."getty@tty1".enable  = false;
  systemd.services."autovt@tty1".enable = false;

  # Enable sound with pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };

  # Battery / power management — important for laptops
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm-autologin.enableGnomeKeyring = true;

  # Touchscreen and touchpad support
  services.libinput.enable      = true;
  services.xserver.wacom.enable = true;

  # Main user account
  users.users.user = {
    isNormalUser    = true;
    description     = "Utilisateur";
    extraGroups     = [ "networkmanager" "wheel" "video" "input" ];
    initialPassword = "pass";
  };

  # Swap — 4GB virtual memory
  swapDevices = [{
    device = "/var/lib/swapfile";
    size   = 4096;
  }];

  # Nix settings — flakes + wheel users can use binary caches
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users         = [ "root" "@wheel" ];
  };

  nixpkgs.config.allowUnfree = true;

  # Git global defaults
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      pull.rebase        = true;
    };
  };

  # ─── Static assets bundled into the system ───────────────────────────────
  environment.etc = {
    "backgrounds/do2-wallpaper.png".source = ./assets/do2-wallpaper.png;

    # Web-app icons
    "icons/teams.png".source      = ./assets/teams.png;
    "icons/gmail.png".source      = ./assets/gmail.png;
    "icons/meet.png".source       = ./assets/meet.png;
    "icons/outlook.png".source    = ./assets/outlook.png;
    "icons/excalidraw.png".source = ./assets/excalidraw.png;

    # First-boot welcome script
    "scripts/do2-welcome.sh" = {
      source = ./do2-welcome.sh;
      mode   = "0755";
    };

    # XDG autostart — GNOME launches this after every login
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

  # ─── System packages ─────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    (google-chrome.override {
      commandLineArgs = "--password-store=basic --no-first-run --no-default-browser-check";
    })
    libreoffice-fresh
    dialect          # GTK translator (Google, DeepL, LibreTranslate)
    mpv              # Lightweight video player
    zoom-us          # Zoom meeting client (native)
    yad              # GTK dialog toolkit — powers the welcome popup
    bat              # Better cat with syntax highlighting
    fastfetch        # Clean system-info display
    tree             # Directory tree viewer
    curl             # HTTP client
    gnomeExtensions.dash-to-dock
    gnomeExtensions.no-overview

    # ── Web-app launchers ─────────────────────────────────────────────────
    (pkgs.makeDesktopItem {
      name        = "microsoft-teams-web";
      desktopName = "Microsoft Teams";
      exec        = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://teams.microsoft.com";
      icon        = "/etc/icons/teams.png";
      categories  = [ "Network" "InstantMessaging" ];
      comment     = "Microsoft Teams (web)";
    })
    (pkgs.makeDesktopItem {
      name        = "gmail-web";
      desktopName = "Gmail";
      exec        = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://mail.google.com";
      icon        = "/etc/icons/gmail.png";
      categories  = [ "Network" "Email" ];
      comment     = "Gmail (web)";
    })
    (pkgs.makeDesktopItem {
      name        = "google-meet-web";
      desktopName = "Google Meet";
      exec        = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://meet.google.com";
      icon        = "/etc/icons/meet.png";
      categories  = [ "Network" "VideoConference" ];
      comment     = "Google Meet (web)";
    })
    (pkgs.makeDesktopItem {
      name        = "outlook-web";
      desktopName = "Outlook";
      exec        = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://outlook.live.com";
      icon        = "/etc/icons/outlook.png";
      categories  = [ "Network" "Email" ];
      comment     = "Outlook (web)";
    })
    (pkgs.makeDesktopItem {
      name        = "excalidraw-web";
      desktopName = "Excalidraw";
      exec        = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://excalidraw.com";
      icon        = "/etc/icons/excalidraw.png";
      categories  = [ "Graphics" "2DGraphics" ];
      comment     = "Tableau de dessin collaboratif (web)";
    })
  ];

  # ─── Remove unwanted default GNOME applications ──────────────────────────
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-connections
    gedit
    epiphany
    geary
    evince
    totem
    gnome-music
    gnome-characters
    gnome-contacts
    gnome-initial-setup
    gnome-maps
    gnome-weather
    gnome-clocks
    gnome-software
    gnome-calendar
    gnome-system-monitor
    gnome-calculator
    gnome-logs
    gnome-font-viewer
    gnome-disk-utility
    simple-scan
    cheese
    yelp
    file-roller
    seahorse
  ];

  # ─── GNOME / dconf settings ──────────────────────────────────────────────
  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [{
    settings = {

      # ── Shell & extensions ────────────────────────────────────────────────
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions      = [
          "dash-to-dock@micxgx.gmail.com"
          "no-overview@fthx"
        ];
        favorite-apps = [
          "google-chrome.desktop"
          "org.gnome.Nautilus.desktop"
        ];
      };

      # Dash to Dock — floating bottom bar
      "org/gnome/shell/extensions/dash-to-dock" = {
        dock-position    = "BOTTOM";
        show-apps-at-top = false;
        extend-height    = false;
        show-trash       = false;
        show-mounts      = false;
      };

      # ── App drawer folders ────────────────────────────────────────────────
      "org/gnome/desktop/app-folders" = {
        folder-children = [ "LibreOffice" "Communication" "Medias" ];
      };
      "org/gnome/desktop/app-folders/folders/LibreOffice" = {
        name = "LibreOffice";
        apps = [
          "libreoffice-startcenter.desktop"
          "libreoffice-writer.desktop"
          "libreoffice-calc.desktop"
          "libreoffice-impress.desktop"
          "libreoffice-draw.desktop"
          "libreoffice-math.desktop"
          "libreoffice-base.desktop"
        ];
      };
      "org/gnome/desktop/app-folders/folders/Communication" = {
        name = "Communication";
        apps = [
          "gmail-web.desktop"
          "microsoft-teams-web.desktop"
          "google-meet-web.desktop"
          "outlook-web.desktop"
          "Zoom.desktop"
        ];
      };
      "org/gnome/desktop/app-folders/folders/Medias" = {
        name = "Médias";
        apps = [
          "mpv.desktop"
          "excalidraw-web.desktop"
        ];
      };

      # ── Workspaces ────────────────────────────────────────────────────────
      "org/gnome/mutter" = {
        dynamic-workspaces = false;
      };
      "org/gnome/desktop/wm/preferences" = {
        num-workspaces = lib.gvariant.mkInt32 1;
      };

      # ── Wallpaper ─────────────────────────────────────────────────────────
      "org/gnome/desktop/background" = {
        picture-uri      = "file:///etc/backgrounds/do2-wallpaper.png";
        picture-uri-dark = "file:///etc/backgrounds/do2-wallpaper.png";
      };

    };
  }];

  # ─── Fonts ───────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    liberation_ttf
  ];

  system.stateVersion = "25.11";
}
