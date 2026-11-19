# Applications pre-installees, applications web, Flatpak, logitheque.
{ pkgs, lib, live, ... }:

let
  # Chrome sans assistant de premier lancement.
  chrome = pkgs.google-chrome.override {
    commandLineArgs = "--no-first-run --no-default-browser-check";
  };

  # Fonction pour créer une application web Chrome
  chromeApp = url:
    "${chrome}/bin/google-chrome-stable "
    + "--ozone-platform-hint=auto "
    + "--disable-backgrounding-occluded-windows "
    + "--disable-renderer-backgrounding "
    + "--app=${url}";

  browser = if live then "firefox.desktop" else "google-chrome.desktop";

in
{
  # Métadonnées des paquets (catalogue « Logiciels » pour les apps .deb / rpm via PackageKit).
  appstream.enable = true;

  # Intégration micrologiciels dans Logiciels (onglet matériel) ; sans impact si indisponible.
  services.fwupd.enable = lib.mkDefault true;

  # ── Variables d'environnement ───────────────────────────────────────────
  environment.variables = {
    SAL_USE_VCLPLUGIN = "gtk3";
    LANGUAGE          = "fr_CA:fr";
    ANKI_LANG = "fr_CA";
  };

  # ── Icônes pour les applications web ────────────────────────────────────
  environment.etc = {
    "icons/teams.png".source      = ../assets/teams.png;
    "icons/outlook.png".source    = ../assets/outlook.png;
    "icons/excalidraw.png".source = ../assets/excalidraw.png;
    "icons/meet.png".source       = ../assets/meet.png;
  };

  # ── Paquets système ─────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Navigateur
    pkgs.adwaita-qt
    firefox

    # Bureautique
    libreoffice
    anki
    xournalpp

    # Médias
    vlc
    gimp
    obs-studio
    audacity

    # Dictionnaire hors ligne (natif — disponible dès le premier démarrage)
    goldendict-ng

    # Traducteur (Google Translate, DeepL, LibreTranslate)
    dialect

    # Utilitaires
    yad
    gnome-calculator
    flameshot
    xed-editor
    system-config-printer
    gnome-software
    flatpak
    qbittorrent
    libnotify
    gawk
    sudo

  ] ++ lib.optionals (!live) [
    chrome
    zoom-us
    teamviewer

    # ── Applications web (raccourcis Chrome) ────────────────────────────
    (pkgs.makeDesktopItem {
      name        = "microsoft-teams-web";
      desktopName = "Microsoft Teams";
      exec        = chromeApp "https://teams.microsoft.com";
      icon        = "/etc/icons/teams.png";
      categories  = [ "Network" "InstantMessaging" ];
      comment     = "Microsoft Teams (web)";
    })
    (pkgs.makeDesktopItem {
      name        = "outlook-web";
      desktopName = "Outlook";
      exec        = chromeApp "https://outlook.live.com";
      icon        = "/etc/icons/outlook.png";
      categories  = [ "Network" "Email" ];
      comment     = "Microsoft Outlook (web)";
    })
    (pkgs.makeDesktopItem {
      name        = "excalidraw-web";
      desktopName = "Excalidraw";
      exec        = chromeApp "https://excalidraw.com";
      icon        = "/etc/icons/excalidraw.png";
      categories  = [ "Graphics" "2DGraphics" ];
      comment     = "Tableau de dessin collaboratif (web)";
    })
    (pkgs.makeDesktopItem {
      name        = "google-meet-web";
      desktopName = "Google Meet";
      exec        = chromeApp "https://meet.google.com";
      icon        = "/etc/icons/meet.png";
      categories  = [ "Network" "VideoConference" ];
      comment     = "Google Meet (web)";
    })

    # Gestionnaire de lien zoommtg://
    (pkgs.makeDesktopItem {
      name         = "zoommtg-handler";
      desktopName  = "Zoom URI Handler";
      exec         = "${pkgs.zoom-us}/bin/zoom-us %u";
      mimeTypes    = [ "x-scheme-handler/zoommtg" "x-scheme-handler/zoomus" ];
      noDisplay    = true;
      type         = "Application";
    })
  ];

  # ── Flatpak (pour que les utilisateurs puissent installer des apps) ────
  services.flatpak.enable = true;

  # ── Portails XDG (requis pour Flatpak et dialogues de fichiers) ─────────
  xdg.portal = {
    enable       = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  # ── TeamViewer (daemon nécessaire pour fonctionner) ─────────────────────
  services.teamviewer.enable = !live;

  # Flathub (declaratif via nix-flatpak — les utilisateurs installent ce qu'ils veulent)
  services.flatpak.remotes = [{
    name     = "flathub";
    location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
  }];

  # ── Associations de fichiers par défaut ─────────────────────────────────
  xdg.mime.defaultApplications = {
    "text/html"                = browser;
    "x-scheme-handler/http"    = browser;
    "x-scheme-handler/https"   = browser;
    "x-scheme-handler/about"   = browser;
    "x-scheme-handler/unknown" = browser;
    "application/pdf"          = browser;
    "inode/directory"           = "nemo.desktop";
    "x-scheme-handler/zoommtg" = "zoommtg-handler.desktop";
    "x-scheme-handler/zoomus"  = "zoommtg-handler.desktop";
  };
}
