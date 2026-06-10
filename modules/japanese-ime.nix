# Saisie japonaise optionnelle (Mozc via fcitx5).
# Active seulement si /var/lib/do2/japanese-ime.enabled existe.
{ pkgs, ... }:

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
            ActiveByDefault = false;
            ShareInputState = "No";
          };
          Hotkey = {
            EnumerateWithTriggerKeys = true;
            TriggerKeys = "Control+Shift+space Alt+Shift+j";
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

  environment.etc."do2/do2-fcitx5-autostart.sh" = {
    source = ../scripts/do2-fcitx5-autostart.sh;
    mode   = "0755";
  };

  # Un seul autostart DO2 (evite double lancement + conflit D-Bus).
  environment.etc."xdg/autostart/do2-fcitx5.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=DO2 Fcitx5
    Comment=Japanese input method
    Exec=/etc/do2/do2-fcitx5-autostart.sh
    X-GNOME-Autostart-enabled=true
    NoDisplay=true
  '';

  # Masquer l'autostart du paquet fcitx5 (sinon deux instances au login).
  environment.etc."xdg/autostart/org.fcitx.Fcitx5.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Hidden=true
    NoDisplay=true
  '';
}
