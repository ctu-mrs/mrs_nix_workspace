export NIXPKGS_ALLOW_UNFREE=1
export NIXPKGS_ALLOW_INSECURE=1

nix develop --impure --accept-flake-config --refresh
