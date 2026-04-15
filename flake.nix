{
  description = "DO2 - Dons d'ordinateurs, 2e vie — Stable & Compatible";

  inputs = {
    # Switching to Stable (24.11) for maximum compatibility on old CPUs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations.do2 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs self; };
      modules = [
        inputs.disko.nixosModules.disko
        ./disko-config.nix
        ./configuration.nix
      ];
    };
  };
}

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
