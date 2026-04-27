# CLI tools -- shared across all profiles.
# HM handles shell integration (init, keybindings) automatically.
{ pkgs, ... }:

{
  programs.starship = {
    enable = true;
    settings = {
      # Clean prompt -- hide verbose SSH hostname
      hostname.disabled = true;
      username.disabled = true;
    };
  };

  programs.fzf = {
    enable = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [ "--height 40%" "--layout=reverse" "--border" ];
  };

  programs.zoxide.enable = true;

  programs.bat = {
    enable = true;
    config.pager = "less -FR";
  };

  programs.lsd.enable = true;

  programs.ripgrep.enable = true;
  programs.fd.enable = true;

  # Man pager via bat
  home.sessionVariables = {
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";
  };
}
