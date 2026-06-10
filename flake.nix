{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";

    nix-mrs-overlay.url = "github:ctu-mrs/nix-mrs-overlay/master";

    nixpkgs.follows = "nix-mrs-overlay/nixpkgs";

    nix-ros-overlay.follows = "nix-mrs-overlay/nix-ros-overlay";

    nixgl.url = "git+https://github.com/nix-community/nixGL.git?ref=refs/pull/223/head";
  };

  outputs = inputs@{ flake-parts, ... }:

    flake-parts.lib.mkFlake { inherit inputs; } {

      imports = [
        inputs.devenv.flakeModule
      ];

      systems = [ "x86_64-linux" ];

      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
        in
        {

          devenv.shells.default = {

            name = "mrs-dev-shell";

            _module.args = {
              inherit system;
              inherit inputs;
            };

            devenv.root =
              let
                folder = builtins.getEnv "PWD";
                isInsideWorkTree = folder != "";
              in
                if isInsideWorkTree
                then folder
                else "${./.}";

            imports = [ ./devenv.nix ];
          };
        };

      flake = {

        nixConfig = {
          extra-substituters = [ "https://ctu-mrs.cachix.org" "https://ros.cachix.org" "https://devenv.cachix.org" ];
          extra-trusted-public-keys = [ "ctu-mrs.cachix.org-1:dnw2ixFgGHfTb4bE1MWQTetAUJe9zqKUOBlrTjDuDMI=" "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" ];
        };

      };

    };
}
