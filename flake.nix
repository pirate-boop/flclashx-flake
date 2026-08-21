{
  description = "FlClashX - Modern Clash Meta GUI for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = self.packages.${system}.flclashx;
        packages.flclashx = pkgs.callPackage ./package.nix { };
        
        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.flclashx;
        };
      }
    ) // {
      overlays.default = final: prev: {
        flclashx = prev.callPackage ./package.nix { };
      };
    };
}
