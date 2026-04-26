{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Search and navigation
    ripgrep
    fd
    fzf
    zoxide

    # Better defaults
    lsd
    bat
  ];

  environment.sessionVariables = {
    FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
    FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";
  };
}
