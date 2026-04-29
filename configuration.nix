{ config, pkgs, lib, inputs, device, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/core.nix
    ./modules/desktop.nix
    ./modules/software.nix
  ];

  system.stateVersion = "25.11";
}
