{
  description = "Alexander's macOS system config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager,
              nix-homebrew, homebrew-core, homebrew-cask,
              agenix, fenix, ... }:
  let
    user = "dn5v";

    mkDarwinSystem = { hostname, system ? "aarch64-darwin", extraModules ? [] }:
      nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit hostname user; };
        modules = [
          ./hosts/common.nix
          ./hosts/${hostname}.nix

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${user} = {
              imports = [ ./home/common.nix ];
              home.homeDirectory = "/Users/${user}";
            };
            home-manager.extraSpecialArgs = {
              inherit hostname user;
              fenixPkgs = fenix.packages.${system};
              agenixPkgs = agenix.packages.${system};
            };
          }

          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = user;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
              };
              mutableTaps = false;
            };
          }

          agenix.darwinModules.default

          {
            nixpkgs.overlays = [ (import ./overlays/default.nix) ];
          }
        ] ++ extraModules;
      };
  in
  {
    darwinConfigurations = {
      personal-mbp = mkDarwinSystem { hostname = "personal-mbp"; };

      # Uncomment when you set up your work machine
      # work-mbp = mkDarwinSystem { hostname = "work-mbp"; };
    };
    templates = {
      python = {
        path = ./templates/python;
        description = "Python project with uv/ruff/ty";
      };
      rust = {
        path = ./templates/rust;
        description = "Rust project with fenix toolchain";
      };
      terraform = {
        path = ./templates/terraform;
        description = "Terraform project";
      };
    };
  };
}
