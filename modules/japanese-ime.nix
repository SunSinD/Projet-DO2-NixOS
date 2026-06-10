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
}
