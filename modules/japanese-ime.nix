# Saisie japonaise optionnelle (Mozc via fcitx5).
# Active seulement si /var/lib/do2/japanese-ime.enabled existe.
{ pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend  = false;
      ignoreUserConfig = false;
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

  environment.etc."xdg/autostart/do2-fcitx5.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=DO2 Fcitx5
    Exec=/etc/do2/do2-fcitx5-autostart.sh
    X-GNOME-Autostart-enabled=true
    NoDisplay=true
  '';

  # Evite deux lancements au login (conflit D-Bus).
  environment.etc."xdg/autostart/org.fcitx.Fcitx5.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Hidden=true
    NoDisplay=true
  '';
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
  ];
}
