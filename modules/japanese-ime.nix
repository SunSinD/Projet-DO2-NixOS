# Saisie japonaise optionnelle (Mozc via fcitx5).
# Active seulement si /var/lib/do2/japanese-ime.enabled existe.
{ config, lib, pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend  = false;
      ignoreUserConfig = true;
      addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
        kdePackages.fcitx5-qt
      ];
      settings = {
        globalOptions = {
          Behavior = {
            ActiveByDefault = true;
            ShareInputState = "No";
          };
          Hotkey = {
            EnumerateWithTriggerKeys = true;
            TriggerKeys = "Control+Shift+space";
          };
        };
        inputMethod = {
          GroupOrder."0" = "Default";
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "ca";
            DefaultIM = "keyboard-ca";
          };
          "Groups/0/Items/0".Name = "keyboard-ca";
          "Groups/0/Items/1".Name = "mozc";
        };
        addons = {
          classicui.globalSection = {
            ShowLayoutNameInIcon = false;
          };
        };
      };
    };
  };

  environment.etc."xdg/autostart/do2-fcitx5.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Fcitx5
    Exec=fcitx5 -d
    X-GNOME-Autostart-enabled=true
    NoDisplay=true
  '';

  systemd.user.services.do2-fcitx5 = {
    description = "Fcitx5 input method (DO2)";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "forking";
      ExecStart = "${lib.getExe config.i18n.inputMethod.package}";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
