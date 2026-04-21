# Auto-import all modules in this directory.
# Note: nvidia.nix and intel.nix are excluded - they must be explicitly imported per-host.
{ ... }:
{
  imports = builtins.map
    (f: ./. + "/${f}")
    (builtins.filter
      (f: f != "default.nix" && f != "nvidia.nix" && f != "intel.nix" && builtins.match ".*\\.nix" f != null)
      (builtins.attrNames (builtins.readDir ./.))
    );
}
