{
  description = "DO2 - Dons d'ordinateurs, 2e vie - College Montmorency";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    disko.url   = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
  };

  outputs = inputs@{ nixpkgs, ... }:
  let
    nemoOverlay = {
      nixpkgs.overlays = [
        (final: prev: {
          nemo = prev.nemo.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              ./patches/nemo-hide-filesystem-sidebar.patch
            ];
          });
        })
      ];
    };
  in {
    packages.x86_64-linux.disko = inputs.disko.packages.x86_64-linux.disko;

    nixosConfigurations.do2 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        live = false;
        # do2-install.sh replaces this line (marker must stay: # DO2_DISK)
        device = "/dev/sda"; # DO2_DISK
      };
      modules = [
        nemoOverlay
        inputs.disko.nixosModules.disko
        inputs.nix-flatpak.nixosModules.nix-flatpak
        ./disko-config.nix
        ./configuration.nix
      ];
    };

    nixosConfigurations.do2-iso = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        do2Source = nixpkgs.lib.fileset.toSource {
          root = ./.;
          fileset = nixpkgs.lib.fileset.unions [
            ./LICENSE
            ./README.md
            ./flake.nix
            ./flake.lock
            ./configuration.nix
            ./disko-config.nix
            ./hardware-configuration.nix
            ./assets
            ./config
            ./guides
            ./modules
            ./patches
            ./scripts
          ];
        };
        device = "/dev/sda";
        live = true;
      };
      modules = [
        nemoOverlay
        inputs.nix-flatpak.nixosModules.nix-flatpak
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
        ./configuration.nix
        ./modules/iso.nix
      ];
    };
  };
}
