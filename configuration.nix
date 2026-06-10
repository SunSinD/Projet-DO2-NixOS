{ config, pkgs, lib, inputs, device, ... }:

let
  # Chemin absolu : local.nix est gitignore, les flakes ne voient pas ./local.nix.
  localCfg = /etc/nixos/config/local.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ./modules/core.nix
    ./modules/desktop.nix
    ./modules/software.nix
    ./modules/beginner-ux.nix
  ]
  ++ lib.optionals (builtins.pathExists localCfg) [ localCfg ];

  system.stateVersion = "25.11";
}
