# nvidia etc.
export NIXPKGS_ALLOW_UNFREE=1

# nix develop --impure --accept-flake-config
nix develop --impure --accept-flake-config --override-input nix-mrs-overlay /home/klaxalk/nix/nix-mrs-overlay
