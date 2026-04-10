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

  # Fixes "download buffer is full" and enables Flakes globally
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    download-buffer-size = 134217728; # 128MB
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs;
  [
    google-chrome
    libreoffice-fresh
    dialect
    vlc
    gnomeExtensions.dash-to-dock # Added to provide a permanent app dock
    
    # Microsoft Teams Web App
    (pkgs.makeDesktopItem {
      name        = "microsoft-teams-web";
      desktopName = "Microsoft Teams";
      exec        = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://teams.microsoft.com";
      icon        = "google-chrome";
      categories  = [ "Network" "InstantMessaging" ];
      comment     = "Microsoft Teams (web)";
    })
    
    # Gmail Web App
    (pkgs.makeDesktopItem {
      name        = "gmail-web";
      desktopName = "Gmail";
      exec        = "${pkgs.google-chrome}/bin/google-chrome-stable --app=https://mail.google.com";
      icon        = "google-chrome";
      categories  = [ "Network" "Email" ];
      comment     = "Gmail (Web)";
    })
  ];

  # Remove unwanted default GNOME applications
  environment.gnome.excludePackages = with pkgs; [ 
    gnome-tour 
    epiphany       # "Web" browser
    geary          # Email client
    gnome-calendar # "Agenda"
    gnome-music    # "Musique"
  ];

  # Force GNOME settings (Enable the dock and pin favorite apps)
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [ "dash-to-dock@micxgx.gmail.com" ];
        favorite-apps = [
          "google-chrome.desktop"
          "gmail-web.desktop"
          "microsoft-teams-web.desktop"
          "libreoffice-start.desktop"
          "org.gnome.Nautilus.desktop" # Fichiers
        ];
      };
      
      # UNCOMMENT the section below to set a default wallpaper automatically. 
      # Note: The image must exist at the path you specify before you rebuild.
      # "org/gnome/desktop/background" = {
      #   picture-uri = "file:///home/user/Images/your-wallpaper.jpg";
      #   picture-uri-dark = "file:///home/user/Images/your-wallpaper.jpg";
      # };
    };
  }];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    liberation_ttf
  ];

  system.stateVersion = "25.11";
}
