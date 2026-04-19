# Hawker environment setup
# HAWKER_PATH is set by NixOS session variables (modules/core/hawker-scripts.nix)
# This file is kept as a fallback for non-NixOS environments (containers, remote hosts)

if test -z "$HAWKER_PATH"
    set -gx HAWKER_PATH "$HOME/.local/share/hawker"
end
