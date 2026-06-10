{ config, pkgs, lib, inputs, device, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/core.nix
    ./modules/desktop.nix
    ./modules/software.nix
    ./modules/beginner-ux.nix
  ]
  ++ lib.optionals (builtins.pathExists ./local.nix) [ ./local.nix ];

  system.stateVersion = "25.11";
}
