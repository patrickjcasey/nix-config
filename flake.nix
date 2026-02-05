{
  description = "NixOS Configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code = {
      url = "github:ryoppippi/claude-code-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, claude-code, ... }: {
    nixosConfigurations.octane = nixpkgs.lib.nixosSystem {
      modules = [
        {
          nixpkgs.hostPlatform = "x86_64-linux";
          nixpkgs.overlays = [ claude-code.overlays.default ];
        }
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.trick = import ./home.nix;
            backupFileExtension = "backup";
          };
        }
      ];
    };
  };
}

