{ config, pkgs, inputs, device, ... }: 

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    efi.canTouchEfiVariables = false;
    efi.efiSysMountPoint     = "/boot";
    grub = {
      enable                = true;
      efiSupport            = true;
      efiInstallAsRemovable = true;
      device                = device;
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

  # Enables Flakes globally
  Nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  # ---> MAGIC HAPPENS HERE: We copy your local images into the system itself <---
  environment.etc = {
    "backgrounds/do2-wallpaper.png".source = ./do2-wallpaper.png;
    "icons/teams.png".source = ./teams.png;
    "icons/gmail.png".source = ./gmail.png;
  };

  environment.systemPackages = with pkgs;
  [
    git # Added git permanently to the system
    google-chrome
    libreoffice-fresh
    dialect
    vlc
    gnomeExtensions.dash-to-dock 
    
    # Microsoft Teams Web App (Now uses your custom icon)
    (pkgs.makeDesktopItem {
      name        = "microsoft-teams-web";
      desktopName = "Microsoft Teams";
      exec        = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://teams.microsoft.com";
      icon        = "/etc/icons/teams.png"; 
      categories  = [ "Network" "InstantMessaging" ];
      comment     = "Microsoft Teams (web)";
    })
    
    # Gmail Web App (Now uses your custom icon)
    (pkgs.makeDesktopItem {
      name        = "gmail-web";
      desktopName = "Gmail";
      exec        = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://mail.google.com";
      icon        = "/etc/icons/gmail.png"; 
      categories  = [ "Network" "Email" ];
      comment     = "Gmail (Web)";
    })
  ];

  # Remove unwanted default GNOME applications
  environment.gnome.excludePackages = with pkgs; [ 
    gnome-tour 
    epiphany       
    geary          
    gnome-calendar 
    gnome-music    
  ];

  # Force GNOME settings for macOS look, single desktop, and custom wallpaper
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [ "dash-to-dock@micxgx.gmail.com" ];
        favorite-apps = [
          "google-chrome.desktop"
          "gmail-web.desktop"
          "microsoft-teams-web.desktop"
          "org.gnome.Nautilus.desktop" # Fichiers (Kept for file management)
        ];
      };
      
      # Dash to Dock (macOS styling)
      "org/gnome/shell/extensions/dash-to-dock" = {
        dock-position = "BOTTOM";
        show-apps-at-top = false; # Puts the 9 dots on the right side
        extend-height = false;    # Makes it a floating dock, not full screen width
        show-trash = false;       # Cleaner look
        show-mounts = false;
      };

      # Disable dynamic workspaces (Lock to 1 desktop)
      "org/gnome/mutter" = {
        dynamic-workspaces = false;
      };
      "org/gnome/desktop/wm/preferences" = {
        num-workspaces = 1;
      };

      # Set the wallpaper permanently
      "org/gnome/desktop/background" = {
        picture-uri = "file:///etc/backgrounds/do2-wallpaper.png";
        picture-uri-dark = "file:///etc/backgrounds/do2-wallpaper.png";
      };
    };
  }];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    liberation_ttf
  ];

  system.stateVersion = "25.11";
}
