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
          # Instantiate the package set with BOTH overlays applied
          rosPkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.nix-ros-overlay.overlays.default
              inputs.nix-mrs-overlay.overlays.default
              inputs.nixgl.overlay
            ];
          };
        in
        {

          devenv.shells.default = {
            name = "mrs-dev-shell";

            # 1. Point directly to the deps.json inside the upstream flake input
            upstreamJsonPath = inputs.nix-mrs-overlay + "/deps.json";
           
            # 2. Parse it exactly as before
            rawDepsMap = builtins.fromJSON (builtins.readFile upstreamJsonPath);
            depsMap = builtins.removeAttrs rawDepsMap [ "_comment" ];
            
            # 3. Define the packages you are locally developing (so we DON'T pull their binaries)
            activePackages = [ "mrs_lib" ];
            
            # 4. Extract ONLY their build dependencies
            extractedDeps = builtins.concatLists (
              map (pkg: depsMap.${pkg}.build_depends or []) activePackages
            );
            
            # Helper to resolve those names into real Nix packages
            # (Make sure to adapt this to however your downstream flake resolves packages)
            resolveDep = name: rosPkgs.rosPackages.jazzy.${name} or pkgs.${name};

            _module.args = {
              inherit rosPkgs;
              inherit resolveDep;
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
