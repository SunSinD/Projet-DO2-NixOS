{
  description = "DO2 - Dons d'ordinateurs, 2e vie — Projet Collège Montmorency";

  inputs = {
    # Using unstable branch (like your friend) for the latest GNOME performance patches
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The secret to your friend's performance: an optimized, responsive kernel
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations.do2 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs self;
        device = "CHANGE_ME"; 
      };
      modules = [
        inputs.disko.nixosModules.disko
        inputs.nix-cachyos-kernel.nixosModules.default # Injects the performance kernel
        ./disko-config.nix
        ./configuration.nix
      ];
    };
  };
}
