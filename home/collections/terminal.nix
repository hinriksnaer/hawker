# Terminal collection -- all terminal tool configs.
# Import this in a profile to get the full terminal setup.
{ ... }:

{
  imports = [
    ../modules/terminal/git.nix
    ../modules/terminal/tmux.nix
    # ../modules/terminal/fish.nix     # add when ready
    # ../modules/terminal/btop.nix     # add when ready
    # ../modules/terminal/neovim.nix   # add when ready
  ];
}
