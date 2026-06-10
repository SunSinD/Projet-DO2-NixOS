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
            # Alt+Shift+J : secours si Ctrl+Shift+Espace ne passe pas (VMware, etc.)
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

  # Demarrer fcitx5 apres Cinnamon (delai 3 s — pas de systemd, evite l'ecran noir).
  environment.etc."xdg/autostart/do2-fcitx5.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=DO2 Fcitx5
    Comment=Japanese input method
    Exec=fcitx5 -d
    X-GNOME-Autostart-enabled=true
    X-GNOME-Autostart-Delay=3
    NoDisplay=true
  '';
}
