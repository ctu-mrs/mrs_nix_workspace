{ pkgs, system, inputs, ... }:
let
  # Instantiate the package set with BOTH overlays applied
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      inputs.nix-ros-overlay.overlays.default
      inputs.nix-mrs-overlay.overlays.default
      inputs.nixgl.overlay
    ];
  };

  ros = pkgs.rosPackages.jazzy;
  mrs = pkgs.mrsCustomPkgs;

  pkgsForDeps = [
    mrs.mrs_lib
    mrs.mrs_multirotor_simulator
    mrs.mrs_uav_autostart
    mrs.mrs_uav_managers
    mrs.mrs_uav_trackers
    mrs.mrs_uav_testing
  ];

  testDeps = pkgs.lib.flatten (map (pkg: pkg.passthru.mrsTestInputs or []) pkgsForDeps);

  myRosEnv = ros.buildEnv {
      name = "mrs-ros-env";
      underlay=true;
      paths = [
        ros.ros-core
        ros.rclpy
        ros.ament-cmake
        ros.ament-cmake-python
        ros.ament-cmake-core
        ros.ament-cmake-clang-format
        ros.python-cmake-module

        ros.rmw-cyclonedds-cpp
        ros.rmw-zenoh-cpp
        ros.rviz2

        mrs.mrs_uav_core
        mrs.mrs_uav_px4_api

      ]
      ++
      testDeps;
    };

in
{
  env.RMW_IMPLEMENTATION="rmw_zenoh_cpp";
  env.RUN_TMUX="false";

  # fixes tmux inside urxvt
  env.TERMINFO_DIRS = "${pkgs.rxvt-unicode-unwrapped.terminfo}/share/terminfo:/usr/share/terminfo:/lib/terminfo";

  # this makes additional RMWs work
  env.LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
    pkgs.rosPackages.jazzy.rmw-zenoh-cpp
    pkgs.rosPackages.jazzy.rmw-cyclonedds-cpp
  ];

  packages = [
    pkgs.tmux
    pkgs.rxvt-unicode-unwrapped.terminfo

    pkgs.colcon
    pkgs.nixgl.auto.nixGLDefault

    # pkgs.lttng-ust

    myRosEnv
  ];

  enterShell = ''
    echo "🔧 Welcome to the MRS devenv environment!"

    export NIX_ENV_ROOT="$PWD"

    # ROS autocomplete
    eval "$(register-python-argcomplete ros2)"
    eval "$(register-python-argcomplete colcon)"

    # for nixGL graphics
    export QT_QPA_PLATFORM=xcb
    export QT_X11_NO_MITSHM=1

    # for nvidia+integrated hybrid systems
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only

    if command -v nixGL &> /dev/null; then
      echo "WARNING: Globally injecting host graphics drivers into shell..."

      export LD_LIBRARY_PATH=$(nixGL printenv LD_LIBRARY_PATH):$LD_LIBRARY_PATH
      export LIBGL_DRIVERS_PATH=$(nixGL printenv LIBGL_DRIVERS_PATH)
      export __EGL_VENDOR_LIBRARY_FILENAMES=$(nixGL printenv __EGL_VENDOR_LIBRARY_FILENAMES)
    else
      echo "not running with nixGL"
    fi

    # Force xmllint to use the local schema catalog
    # fixes lint tests
    export XML_CATALOG_FILES="`ros2 pkg prefix ament_package`/share/ament_package/template/catalog.xml"

    [ -f ./install/setup.sh ] && source ./install/setup.sh
  '';
}
