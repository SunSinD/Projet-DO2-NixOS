{
  description = "DO2 - Dons d'ordinateurs, 2e vie - College Montmorency";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    disko.url   = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
  };

  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations.do2 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs self;
        # do2-install.sh replaces this line (marker must stay: # DO2_DISK)
        device = "/dev/sda"; # DO2_DISK
      };
      modules = [
        # Overlay must apply before modules read pkgs (e.g. cinnamon → nemo-with-extensions → nemo).
        (
          { ... }:
          {
            nixpkgs.overlays = [
              (final: prev: {
                nemo = prev.nemo.overrideAttrs (old: {
                  patches = (old.patches or [ ]) ++ [
                    ./patches/nemo-hide-filesystem-sidebar.patch
                  ];
                });
              })
            ];
          }
        )
        inputs.disko.nixosModules.disko
        inputs.nix-flatpak.nixosModules.nix-flatpak
        ./disko-config.nix
        ./configuration.nix
      ];
    };
  };
}
