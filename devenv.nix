{ rosPkgs, rosDeps, ... }:
let
  ros = rosPkgs.rosPackages.jazzy;
  deps = rosDeps;
in
{
  env.RMW_IMPLEMENTATION=rmw_fastrtps_cpp

  packages = [ rosPkgs.colcon (ros.buildEnv { paths = deps; }) ];

  enterShell = ''
    echo "🔧 Welcome to the MRS devenv environment!"
  '';
}
