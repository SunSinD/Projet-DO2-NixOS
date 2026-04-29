{ config, pkgs, lib, inputs, device, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/core.nix
    ./modules/desktop.nix
    ./modules/software.nix
    ./modules/beginner-ux.nix
  ];

  system.stateVersion = "25.11";
}
