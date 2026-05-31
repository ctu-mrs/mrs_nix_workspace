{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";

    # 1. Pull in your monolithic overlay
    nix-mrs-overlay.url = "github:ctu-mrs/nix-mrs-overlay/master";

    # 2. THE CACHE GUARANTEE: Force this workspace to use the exact
    # same nixpkgs and ros-overlay that your central cache was built against.
    nixpkgs.follows = "nix-mrs-overlay/nixpkgs";
    nix-ros-overlay.follows = "nix-mrs-overlay/nix-ros-overlay";

    nixgl.url = "github:nix-community/nixGL";
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
              inputs.nix-mrs-overlay.overlays.default # <-- Your custom packages injected here!
              inputs.nixgl.overlay
            ];
          };

          ros = rosPkgs.rosPackages.jazzy;

          rosDeps = [
            ros.ros-core
            ros.sensor-msgs
            ros.ament-cmake-core
            ros.python-cmake-module
            ros.rmw-zenoh-cpp
            ros.rclpy
            ros.rviz2
            
            rosPkgs.mrsCustomPkgs.mrs_multirotor_simulator
            rosPkgs.mrsCustomPkgs.mrs_uav_managers
            rosPkgs.mrsCustomPkgs.mrs_uav_controllers
            rosPkgs.mrsCustomPkgs.mrs_uav_trackers
            rosPkgs.mrsCustomPkgs.mrs_uav_trajectory_generation
            rosPkgs.mrsCustomPkgs.mrs_uav_core

            pkgs.tmux
            pkgs.tmuxinator
          ];
        in
        {
          devenv.shells.default = {
            name = "mrs-dev-shell";

            _module.args = {
              inherit rosPkgs;
              inherit rosDeps;
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
