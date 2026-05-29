{ pkgs, rosPkgs, rosDeps, nixgl, ... }:
let
  ros = rosPkgs.rosPackages.jazzy;
  deps = rosDeps;
in
{
  env.RMW_IMPLEMENTATION="rmw_fastrtps_cpp";
  env.RUN_TMUX="false";
  env.TERMINFO_DIRS = "${pkgs.rxvt-unicode-unwrapped.terminfo}/share/terminfo:/usr/share/terminfo:/lib/terminfo";

  packages = [
    rosPkgs.colcon
    pkgs.tmux
    pkgs.rxvt-unicode-unwrapped.terminfo
    rosPkgs.nixgl.auto.nixGLNvidia
    (ros.buildEnv { paths = deps; })
  ];

  enterShell = ''
    echo "🔧 Welcome to the MRS devenv environment!"

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
      echo "☢️ WARNING: Globally injecting host graphics drivers into shell..."
      
      export LD_LIBRARY_PATH=$(nixGL printenv LD_LIBRARY_PATH):$LD_LIBRARY_PATH
      export LIBGL_DRIVERS_PATH=$(nixGL printenv LIBGL_DRIVERS_PATH)
      export __EGL_VENDOR_LIBRARY_FILENAMES=$(nixGL printenv __EGL_VENDOR_LIBRARY_FILENAMES)
    else
      echo "☢️ not running with libgl"
    fi

  '';
}
