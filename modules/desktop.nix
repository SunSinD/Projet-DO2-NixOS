# GNOME session, audio, input, dconf defaults (lightweight UI on old hardware).
{ config, pkgs, lib, ... }:

{
  services.xserver.xkb.layout  = "us";
  services.xserver.xkb.variant = "";

  services.xserver.enable              = true;
  services.displayManager.gdm.enable   = true;
  services.desktopManager.gnome.enable = true;

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user   = "user";

  systemd.services."getty@tty1".enable  = false;
  systemd.services."autovt@tty1".enable = false;

  security.rtkit.enable = true;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };

  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm-autologin.enableGnomeKeyring = true;

  services.libinput.enable      = true;
  services.xserver.wacom.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany
    geary
    totem
    gnome-music
  ];

  programs.dconf.enable = true;
  programs.dconf.profiles.user.databases = [{
    settings = {

      "org/gnome/desktop/interface" = {
        enable-animations = false;
      };

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

      "org/gnome/shell/extensions/dash-to-dock" = {
        dock-position       = "BOTTOM";
        show-apps-at-top    = false;
        extend-height       = false;
        show-trash          = false;
        show-mounts       = false;
        animate-show-apps = false;
      };

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
          "vlc.desktop"
          "excalidraw-web.desktop"
        ];
      };

      "org/gnome/mutter" = {
        dynamic-workspaces = false;
      };
      "org/gnome/desktop/wm/preferences" = {
        num-workspaces = lib.gvariant.mkInt32 1;
      };

      "org/gnome/desktop/background" = {
        picture-uri      = "file:///etc/backgrounds/do2-wallpaper.png";
        picture-uri-dark = "file:///etc/backgrounds/do2-wallpaper.png";
      };

    };
  }];
}
