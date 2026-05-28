{ rosPkgs, rosDeps, pkgs, ... }:
let
  ros = rosPkgs.rosPackages.jazzy;
  deps = rosDeps;
in
{
 env.RMW_IMPLEMENTATION="rmw_fastrtps_cpp";

  packages = [
    rosPkgs.colcon
    pkgs.rxvt-unicode-unwrapped.terminfo
    (ros.buildEnv { paths = deps; })
  ];

  enterShell = ''
    eval "$(register-python-argcomplete ros2)"
    eval "$(register-python-argcomplete colcon)"
    echo "🔧 Welcome to the MRS devenv environment!"
  '';
}
