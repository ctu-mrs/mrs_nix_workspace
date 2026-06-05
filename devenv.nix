{ pkgs, rosPkgs, resolveDep, nixgl, ... }:
let
  ros = rosPkgs.rosPackages.jazzy;
  mrs = rosPkgs.mrsCustomPkgs;
in
{
  env.RMW_IMPLEMENTATION="rmw_zenoh_cpp";
  env.RUN_TMUX="false";

  # fixes tmux inside urxvt
  env.TERMINFO_DIRS = "${pkgs.rxvt-unicode-unwrapped.terminfo}/share/terminfo:/usr/share/terminfo:/lib/terminfo";

  # this makes additional RMWs work
  env.LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
    rosPkgs.rosPackages.jazzy.rmw-zenoh-cpp
    rosPkgs.rosPackages.jazzy.rmw-cyclonedds-cpp
  ];

  packages = [
    pkgs.tmux
    pkgs.rxvt-unicode-unwrapped.terminfo

    rosPkgs.colcon
    rosPkgs.nixgl.auto.nixGLDefault

    (ros.buildEnv { paths = [
      ros.ament-clang-format
      ros.ament-cmake-clang-format
      ros.ament-lint-auto
      ros.rmw-cyclonedds-cpp
      ros.rmw-zenoh-cpp
      ros.rviz2

      resolveDep;
    ]; })
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

    [ -f ./install/setup.sh ] && source ./install/setup.sh
  '';
}
