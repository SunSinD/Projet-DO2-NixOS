# Bundled assets, packages, fonts, Chrome web apps (with lighter background flags).
{ config, pkgs, ... }:

let
  chrome = pkgs.google-chrome.override {
    commandLineArgs = "--password-store=basic --no-first-run --no-default-browser-check";
  };
  # Desktop Exec= must not use shell quoting; keep a single argv vector as one line.
  chromeApp = url:
    "${chrome}/bin/google-chrome-stable "
    + "--ozone-platform-hint=auto "
    + "--disable-backgrounding-occluded-windows "
    + "--disable-renderer-backgrounding "
    + "--app=${url}";
in
{

  environment.variables = {
    SAL_USE_VCLPLUGIN = "gtk3";
  };

  environment.etc = {
    "backgrounds/do2-wallpaper.png".source = ../assets/do2-wallpaper.png;

    "icons/teams.png".source      = ../assets/teams.png;
    "icons/gmail.png".source      = ../assets/gmail.png;
    "icons/meet.png".source       = ../assets/meet.png;
    "icons/outlook.png".source    = ../assets/outlook.png;
    "icons/excalidraw.png".source = ../assets/excalidraw.png;

    "scripts/do2-welcome.sh" = {
      source = ../do2-welcome.sh;
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

  environment.systemPackages = with pkgs; [
    chrome
    libreoffice-fresh
    dialect
    vlc
    zoom-us
    yad
    bat
    fastfetch
    tree
    curl
    gnomeExtensions.dash-to-dock
    gnomeExtensions.no-overview

    (pkgs.makeDesktopItem {
      name        = "microsoft-teams-web";
      desktopName = "Microsoft Teams";
      exec        = chromeApp "https://teams.microsoft.com";
      icon        = "/etc/icons/teams.png";
      categories  = [ "Network" "InstantMessaging" ];
      comment     = "Microsoft Teams (web)";
    })
    (pkgs.makeDesktopItem {
      name        = "gmail-web";
      desktopName = "Gmail";
      exec        = chromeApp "https://mail.google.com";
      icon        = "/etc/icons/gmail.png";
      categories  = [ "Network" "Email" ];
      comment     = "Gmail (web)";
    })
    (pkgs.makeDesktopItem {
      name        = "google-meet-web";
      desktopName = "Google Meet";
      exec        = chromeApp "https://meet.google.com";
      icon        = "/etc/icons/meet.png";
      categories  = [ "Network" "VideoConference" ];
      comment     = "Google Meet (web)";
    })
    (pkgs.makeDesktopItem {
      name        = "outlook-web";
      desktopName = "Outlook";
      exec        = chromeApp "https://outlook.live.com";
      icon        = "/etc/icons/outlook.png";
      categories  = [ "Network" "Email" ];
      comment     = "Outlook (web)";
    })
    (pkgs.makeDesktopItem {
      name        = "excalidraw-web";
      desktopName = "Excalidraw";
      exec        = chromeApp "https://excalidraw.com";
      icon        = "/etc/icons/excalidraw.png";
      categories  = [ "Graphics" "2DGraphics" ];
      comment     = "Tableau de dessin collaboratif (web)";
    })
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    liberation_ttf
  ];
}
