# Git configuration -- generates .gitconfig from settings.nix
# Replaces the bootstrap.sh git config generation.
{ pkgs, settings, ... }:

let
  gitSettings = settings.git or {};
  name = gitSettings.name or "user";
  email = gitSettings.email or "user@localhost";
in
{
  environment.systemPackages = [ pkgs.git ];

  # Generate .gitconfig for the user via activation script
  system.activationScripts.gitconfig = ''
    GITCONFIG="/home/${settings.username}/.gitconfig"
    if [ ! -f "$GITCONFIG" ]; then
      cat > "$GITCONFIG" <<'EOF'
[user]
    name = ${name}
    email = ${email}

[core]
    editor = nvim

[init]
    defaultBranch = main

[pull]
    rebase = false
EOF
      chown ${settings.username}:users "$GITCONFIG"
    fi
  '';
}
