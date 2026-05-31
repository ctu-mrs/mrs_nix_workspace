{
  inputs = {
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";

    nix-mrs-overlay.url = "github:ctu-mrs/nix-mrs-overlay/master";

    nixpkgs.follows = "nix-mrs-overlay/nixpkgs";
  };

  outputs = { self, nix-ros-overlay, nix-mrs-overlay, nixpkgs }:
    nix-ros-overlay.inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            nix-ros-overlay.overlays.default
            nix-mrs-overlay.overlays.default
          ];
        };
      in {
        devShells.default = pkgs.mkShell {

          name = "MRS shell";

          packages = [
            pkgs.colcon
            pkgs.tmux
            pkgs.tmuxinator

            # ... other non-ROS packages
            (with pkgs.rosPackages.jazzy; buildEnv {
              paths = [
                ros-core
                rviz2

                mrsCustomPkgs.mrs_multirotor_simulator
                mrsCustomPkgs.mrs_uav_managers
                mrsCustomPkgs.mrs_uav_controllers
                mrsCustomPkgs.mrs_uav_trackers
                mrsCustomPkgs.mrs_uav_trajectory_generation
                mrsCustomPkgs.mrs_uav_core
              ];
            })
          ];
        };
      });

    nixConfig = {
      extra-substituters = [ "https://ctu-mrs.cachix.org" "https://ros.cachix.org" "https://devenv.cachix.org" ];
      extra-trusted-public-keys = [ "ctu-mrs.cachix.org-1:dnw2ixFgGHfTb4bE1MWQTetAUJe9zqKUOBlrTjDuDMI=" "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" ];
    };
}
