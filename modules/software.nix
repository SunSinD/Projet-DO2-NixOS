# Applications pre-installees, applications web, Flatpak, logitheque.
{ config, pkgs, lib, ... }:

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
    LANGUAGE          = "fr_CA:fr";
    ANKI_LANG         = "fr_CA";
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
    chrome
    firefox

    # Bureautique
    libreoffice-still
    anki
    xournalpp

    # Communication
    zoom-us
    teamviewer

    # Médias
    vlc
    gimp
    obs-studio
    audacity

    # Traducteur (Google Translate, DeepL, LibreTranslate)
    dialect

    # Utilitaires
    yad
    gnome-calculator
    flameshot
    xed-editor
    system-config-printer
    gnome-software
    qbittorrent
    libnotify
    gawk
    sudo

    # Shutdown/reboot instantané (remplace cinnamon-session-quit)
    (lib.hiPrio (pkgs.writeShellScriptBin "cinnamon-session-quit" ''
      case "$*" in
        *--power-off*) ${pkgs.kbd}/bin/chvt 1; exec systemctl poweroff ;;
        *--reboot*)    ${pkgs.kbd}/bin/chvt 1; exec systemctl reboot ;;
        *) exec /run/current-system/sw/lib/cinnamon-session/cinnamon-session-quit "$@" ;;
      esac
    ''))

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
    (makeDesktopItem {
      name        = "google-meet-web";
      desktopName = "Google Meet";
      exec        = chromeApp "https://meet.google.com";
      icon        = "/etc/icons/meet.png";
      categories  = [ "Network" "VideoConference" ];
      comment     = "Google Meet (web)";
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

  # ── Portails XDG (requis pour Flatpak et dialogues de fichiers) ─────────
  xdg.portal = {
    enable       = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  # ── TeamViewer (daemon nécessaire pour fonctionner) ─────────────────────
  services.teamviewer.enable = true;

  # Installer GoldenDict via Flatpak au premier démarrage réseau
  systemd.services.flatpak-setup-flathub = {
    script = ''
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
      ${pkgs.flatpak}/bin/flatpak install -y flathub io.github.xiaoyifang.goldendict_ng || true
      ${pkgs.flatpak}/bin/flatpak override --system --env=QT_QPA_PLATFORMTHEME= io.github.xiaoyifang.goldendict_ng || true
    '';
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
    };
    wantedBy = [ "multi-user.target" ];
    after    = [ "network-online.target" ];
    wants    = [ "network-online.target" ];
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
