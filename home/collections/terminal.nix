# Terminal collection -- all terminal tool configs.
# Import this in a profile to get the full terminal setup.
{ ... }:

{
  imports = [
    ../modules/terminal/git.nix
    ../modules/terminal/tmux.nix
    ../modules/terminal/cli-tools.nix
    ../modules/terminal/gh.nix
    ../modules/terminal/fish.nix
    # ../modules/terminal/btop.nix     # add when ready
    # ../modules/terminal/neovim.nix   # add when ready
  ];
}
