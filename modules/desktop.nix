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

  environment.gnome.excludePackages = with pkgs;
  [
    gnome-tour
    epiphany
    geary
    totem
    gnome-music
  ];

  systemd.services.reset-user-dconf = {
    description = "Reset user dconf to system defaults";
    before      = [ "display-manager.service" ];
    wantedBy    = [ "multi-user.target" ];
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/rm -f /home/user/.config/dconf/user";
    };
  };

  programs.dconf.enable = true;

  # dconf profile for the "user" account
  environment.etc."dconf/profile/user".text = ''
    user-db:user
    system-db:do2
  '';

  # Write the dconf system database keyfiles and compile them.
  # Using an activation script instead of environment.etc because
  # programs.dconf.enable owns /etc/dconf/ in the Nix store (read-only),
  # which prevents environment.etc from creating symlinks inside it.
  system.activationScripts.dconf-db = {
    deps = [ "etc" ];
    text = ''
      mkdir -p /etc/dconf/db/do2.d/locks

      cat > /etc/dconf/db/do2.d/00-nixos << 'EOF'
[org/gnome/shell]
favorite-apps=['google-chrome.desktop', 'microsoft-teams-web.desktop', 'outlook-web.desktop', 'libreoffice-calc.desktop', 'libreoffice-writer.desktop', 'org.gnome.Nautilus.desktop']
enabled-extensions=['dash-to-dock@micxgx.gmail.com', 'no-overview@fthx']
disable-user-extensions=false

[org/gnome/desktop/interface]
enable-animations=false

[org/gnome/desktop/app-folders]
folder-children=['LibreOffice', 'Communication', 'Médias', 'Internet', 'Outils']

[org/gnome/desktop/app-folders/folders/LibreOffice]
name='LibreOffice'
apps=['libreoffice-startcenter.desktop', 'libreoffice-writer.desktop', 'libreoffice-calc.desktop', 'libreoffice-impress.desktop', 'libreoffice-draw.desktop', 'libreoffice-math.desktop', 'libreoffice-base.desktop']

[org/gnome/desktop/app-folders/folders/Communication]
name='Communication'
apps=['gmail-web.desktop', 'microsoft-teams-web.desktop', 'google-meet-web.desktop', 'outlook-web.desktop', 'Zoom.desktop']

[org/gnome/desktop/app-folders/folders/Médias]
name='Médias'
apps=['vlc.desktop', 'excalidraw-web.desktop', 'gimp.desktop', 'org.gnome.Loupe.desktop', 'eog.desktop']

[org/gnome/desktop/app-folders/folders/Internet]
name='Internet'
apps=['google-chrome.desktop']

[org/gnome/desktop/app-folders/folders/Outils]
name='Outils'
apps=['dialect.desktop', 'yad.desktop', 'xterm.desktop', 'gnome-system-monitor.desktop', 'seahorse.desktop', 'gnome-font-viewer.desktop', 'nixos-manual.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Settings.desktop', 'org.gnome.Calculator.desktop']

[org/gnome/shell/extensions/dash-to-dock]
dock-position='BOTTOM'
show-apps-at-top=false
extend-height=false
show-trash=false
show-mounts=false
animate-show-apps=false

[org/gnome/mutter]
dynamic-workspaces=false

[org/gnome/desktop/wm/preferences]
num-workspaces=1

[org/gnome/desktop/background]
picture-uri='file:///etc/backgrounds/do2-wallpaper.png'
picture-uri-dark='file:///etc/backgrounds/do2-wallpaper.png'
EOF

      cat > /etc/dconf/db/do2.d/locks/00-locks << 'EOF'
/org/gnome/shell/favorite-apps
/org/gnome/shell/enabled-extensions
/org/gnome/desktop/app-folders/folder-children
/org/gnome/desktop/app-folders/folders/LibreOffice/apps
/org/gnome/desktop/app-folders/folders/Communication/apps
/org/gnome/desktop/app-folders/folders/Médias/apps
/org/gnome/desktop/app-folders/folders/Internet/apps
/org/gnome/desktop/app-folders/folders/Outils/apps
EOF

      ${pkgs.dconf}/bin/dconf update
    '';
  };
}
