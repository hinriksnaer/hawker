# Fish shell -- minimal HM config to enable shell integrations.
# This enables programs.starship, programs.fzf, programs.zoxide, etc.
# to generate their fish init files (~/.config/fish/conf.d/).
# The full fish config (vi mode, venv, aliases) remains in the NixOS
# module (modules/core/fish.nix) until fully migrated.
{ ... }:

{
  programs.fish.enable = true;
}
