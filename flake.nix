{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    nixosConfigurations.Metapod = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        sops-nix.nixosModules.sops
        ./nixos/hosts/Metapod/configuration.nix
        ({ ... }: { nix.settings.experimental-features = [ "nix-command" "flakes" ]; })
        home-manager.nixosModules.home-manager
        { home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.diddy = import ./home/diddy/home.nix; }
      ];
    };
  };
}
