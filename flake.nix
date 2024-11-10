{
  description = "Darkwraith Emacs Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    emacs-overlay
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ emacs-overlay.overlay ];
      };
    in
    {
      packages.doom-emacs-scripts = pkgs.stdenv.mkDerivation {
        pname = "doom-emacs-scripts";
        version = "1.0";
        src = "/emacs/bin";

        buildInputs = [ pkgs.emacs ];
        installPhase = ''
          mkdir -p $out/bin
          cp -r * $out/bin/
        '';
      };

      nixosModules.darkwraith-emacs = {
        options.darkwraith-emacs.enable = pkgs.lib.mkOption {
          type = pkgs.lib.types.bool;
          default = false;
          description = "Enable Darkwraith Emacs";
        };

        config = pkgs.lib.mkIf self.config.darkwraith-emacs.enable {
          environment.systemPackages = [ self.packages.${system}.doom-emacs-scripts ];

          home.packages = [ emacs-overlay.packages.${pkgs.system}.emacs-unstable ];

          home.file.".config/doom" = {
            source = self.darkwraith-emacs + "/doom";
          };
          home.file.".config/emacs" = {
            source = self.darkwraith-emacs + "/emacs";
          };
        };
      };
    });
}
