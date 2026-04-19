# Git configuration -- generates .gitconfig from hawker options.
{ pkgs, config, ... }:

let
  cfg = config.hawker;
in
{
  environment.systemPackages = [ pkgs.git ];

  system.activationScripts.gitconfig = ''
    GITCONFIG="/home/${cfg.username}/.gitconfig"
    if [ ! -f "$GITCONFIG" ]; then
      cat > "$GITCONFIG" <<'EOF'
[user]
    name = ${cfg.git.name}
    email = ${cfg.git.email}

[core]
    editor = nvim

[init]
    defaultBranch = main

[pull]
    rebase = false
EOF
      chown ${cfg.username}:users "$GITCONFIG"
    fi
  '';
}
