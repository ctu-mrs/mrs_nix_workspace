# nvidia etc.
export NIXPKGS_ALLOW_UNFREE=1

nix develop --impure --accept-flake-config
# nix develop --impure --accept-flake-config --override-input nix-ros-overlay /home/klaxalk/nix/nix-ros-overlay
