{ config, pkgs, lib, inputs, device, ... }:

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
    ./modules/beginner-ux.nix
  ]
  ++ lib.optionals (builtins.pathExists japaneseMarker) [ ./modules/japanese-ime.nix ];

  system.stateVersion = "25.11";
}
