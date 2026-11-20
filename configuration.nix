{ lib, chromebook, ... }:

let
  # Fichier hors flake : opt-in clavier japonais (do2-japanese-keyboard enable).
  japaneseMarker = /var/lib/do2/japanese-ime.enabled;
in
{
  imports = [
    ./hardware-configuration.nix
    ./modules/core.nix
    ./modules/desktop.nix
    ./modules/software.nix
  ]
  ++ lib.optionals (builtins.pathExists japaneseMarker) [ ./modules/japanese-ime.nix ]
  ++ lib.optionals chromebook [ ./modules/chromebook.nix ];

  system.stateVersion = "25.11";
}
