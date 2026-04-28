# hawker-dev CLI -- available inside `nix develop`.
# Wraps cli/hawker-dev.sh into a Nix package via writeShellScriptBin.
{ pkgs }:

{
  hawker-dev = pkgs.writeShellScriptBin "hawker-dev" (builtins.readFile ./hawker-dev.sh);
}
