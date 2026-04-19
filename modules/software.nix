# Applications pre-installees, applications web, Flatpak, logitheque.
{ config, pkgs, ... }:

let
  # Chrome avec les bons drapeaux (pas de popup de trousseau ni de premier lancement)
  chrome = pkgs.google-chrome.override {
    commandLineArgs = "--password-store=basic --no-first-run --no-default-browser-check";
  };

  # Fonction pour créer une application web Chrome
  chromeApp = url:
    "${chrome}/bin/google-chrome-stable "
    + "--ozone-platform-hint=auto "
    + "--disable-backgrounding-occluded-windows "
    + "--disable-renderer-backgrounding "
    + "--app=${url}";
in
{
  # ── Variables d'environnement ───────────────────────────────────────────
  environment.variables = {
    SAL_USE_VCLPLUGIN = "gtk3";
  };

  # ── Icônes pour les applications web ────────────────────────────────────
  environment.etc = {
    "icons/teams.png".source      = ../assets/teams.png;
    "icons/outlook.png".source    = ../assets/outlook.png;
    "icons/excalidraw.png".source = ../assets/excalidraw.png;
  };

  # ── Paquets système ─────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Navigateur
    chrome

    # Bureautique
    libreoffice-still

    # Communication
    zoom-us

    # Médias
    vlc
    gimp

    # Traducteur (Google Translate, DeepL, LibreTranslate)
    dialect

    # Utilitaires
    yad                   # Dialogues graphiques (bienvenue, scripts)
    gnome-calculator
    gnome-screenshot
    system-config-printer
    gnome-software        # Logithèque pour installer des apps via GUI
    libnotify
    gawk
    sudo

    # Portails XDG (intégration Flatpak / fichiers)
    xdg-desktop-portal
    xdg-desktop-portal-gtk

    # ── Applications web (raccourcis Chrome) ────────────────────────────
    (makeDesktopItem {
      name        = "microsoft-teams-web";
      desktopName = "Microsoft Teams";
      exec        = chromeApp "https://teams.microsoft.com";
      icon        = "/etc/icons/teams.png";
      categories  = [ "Network" "InstantMessaging" ];
      comment     = "Microsoft Teams (web)";
    })
    (makeDesktopItem {
      name        = "outlook-web";
      desktopName = "Outlook";
      exec        = chromeApp "https://outlook.live.com";
      icon        = "/etc/icons/outlook.png";
      categories  = [ "Network" "Email" ];
      comment     = "Microsoft Outlook (web)";
    })
    (makeDesktopItem {
      name        = "excalidraw-web";
      desktopName = "Excalidraw";
      exec        = chromeApp "https://excalidraw.com";
      icon        = "/etc/icons/excalidraw.png";
      categories  = [ "Graphics" "2DGraphics" ];
      comment     = "Tableau de dessin collaboratif (web)";
    })

    # Gestionnaire de lien zoommtg://
    (makeDesktopItem {
      name         = "zoommtg-handler";
      desktopName  = "Zoom URI Handler";
      exec         = "${zoom-us}/bin/zoom-us %u";
      mimeTypes    = [ "x-scheme-handler/zoommtg" "x-scheme-handler/zoomus" ];
      noDisplay    = true;
      type         = "Application";
    })
  ];

  # ── Flatpak (pour que les utilisateurs puissent installer des apps) ────
  services.flatpak.enable = true;
  xdg.portal.enable       = true;

  # Ajouter le dépôt Flathub automatiquement
  systemd.services.flatpak-setup-flathub = {
    script = ''
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
    };
    after    = [ "network-online.target" ];
    wants    = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  # ── Associations de fichiers par défaut ─────────────────────────────────
  xdg.mime.defaultApplications = {
    "text/html"                = "google-chrome.desktop";
    "x-scheme-handler/http"    = "google-chrome.desktop";
    "x-scheme-handler/https"   = "google-chrome.desktop";
    "x-scheme-handler/about"   = "google-chrome.desktop";
    "x-scheme-handler/unknown" = "google-chrome.desktop";
    "application/pdf"          = "google-chrome.desktop";
    "x-scheme-handler/zoommtg" = "zoommtg-handler.desktop";
    "x-scheme-handler/zoomus"  = "zoommtg-handler.desktop";
  };
}
