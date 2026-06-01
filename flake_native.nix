{
  inputs = {

    nix-mrs-overlay.url = "github:ctu-mrs/nix-mrs-overlay/master";

    nixpkgs.follows = "nix-mrs-overlay/nixpkgs";

    nix-ros-overlay.follows = "nix-mrs-overlay/nix-ros-overlay";

    nixgl.url = "github:nix-community/nixGL";
  };

  outputs = { self, nix-ros-overlay, nix-mrs-overlay, nixgl, nixpkgs }:
    nix-ros-overlay.inputs.flake-utils.lib.eachDefaultSystem (system:
      let

        pkgs = import nixpkgs {
          inherit system;
          overlays = [

            nix-ros-overlay.overlays.default
            nix-mrs-overlay.overlays.default
            nixgl.overlay
          ];
        };

        ros = pkgs.rosPackages.jazzy;
        mrs = pkgs.mrsCustomPkgs;

      in {
        devShells.default = pkgs.mkShell {

          name = "MRS shell";

          env.RMW_IMPLEMENTATION="rmw_zenoh_cpp";

          env.TERMINFO_DIRS = "${pkgs.rxvt-unicode-unwrapped.terminfo}/share/terminfo:/usr/share/terminfo:/lib/terminfo";

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.rosPackages.jazzy.rmw-zenoh-cpp
          ];

          packages = [

            pkgs.colcon
            pkgs.tmux
            pkgs.tmuxinator

            ros.ros-core
            ros.rviz2
            ros.rclpy

            mrs.mrs_uav_core

          ];

          shellHook = ''
            echo "🔧 Welcome to the MRS devenv environment!"

            export NIX_ENV_ROOT="$PWD"

            source $NIX_ENV_ROOT/shell_additions.sh

            # for nixGL graphics
            export QT_QPA_PLATFORM=xcb
            export QT_X11_NO_MITSHM=1

            # for nvidia+integrated hybrid systems
            export __NV_PRIME_RENDER_OFFLOAD=1
            export __GLX_VENDOR_LIBRARY_NAME=nvidia
            export __VK_LAYER_NV_optimus=NVIDIA_only

            if command -v nixGL &> /dev/null; then
              echo "☢️ WARNING: Globally injecting host graphics drivers into shell..."

              export LD_LIBRARY_PATH=$(nixGL printenv LD_LIBRARY_PATH):$LD_LIBRARY_PATH
              export LIBGL_DRIVERS_PATH=$(nixGL printenv LIBGL_DRIVERS_PATH)
              export __EGL_VENDOR_LIBRARY_FILENAMES=$(nixGL printenv __EGL_VENDOR_LIBRARY_FILENAMES)
            else
              echo "☢️ not running with nixGL"
            fi

            # ROS autocomplete
            eval "$(register-python-argcomplete ros2)"
            eval "$(register-python-argcomplete colcon)"

            [ -f ./install/setup.sh ] && source ./install/setup.sh
          '';
        };
      });

    nixConfig = {
      extra-substituters = [ "https://ctu-mrs.cachix.org" "https://ros.cachix.org" "https://devenv.cachix.org" ];
      extra-trusted-public-keys = [ "ctu-mrs.cachix.org-1:dnw2ixFgGHfTb4bE1MWQTetAUJe9zqKUOBlrTjDuDMI=" "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" ];
    };
}
