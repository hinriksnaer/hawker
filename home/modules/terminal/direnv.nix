# Direnv + nix-direnv -- auto-enters nix develop environments on cd.
{ ... }:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
