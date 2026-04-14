{
  description = "DO2 - Dons d'ordinateurs, 2e vie — Projet Collège Montmorency";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    disko.url   = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations.do2 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs self;
        device = "/dev/sda"; # Default — replaced at install time by install.sh
      };
      modules = [
        inputs.disko.nixosModules.disko
        ./disko-config.nix
        ./configuration.nix
      ];
    };
  };
}
