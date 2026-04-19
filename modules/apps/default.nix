# Auto-import all modules in this directory.
{ ... }:
{
  imports = builtins.map
    (f: ./. + "/${f}")
    (builtins.filter
      (f: f != "default.nix" && builtins.match ".*\\.nix" f != null)
      (builtins.attrNames (builtins.readDir ./.))
    );
}
