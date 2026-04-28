# btop -- system monitor with config deployed as a copy.
# btop rewrites its config on exit, so we use a copy instead of a symlink.
# Theme switching creates a symlink at ~/.config/btop/themes/active.theme.
{ pkgs, config, ... }:

{
  home.packages = [ pkgs.btop ];

  # Copy btop.conf (not symlink -- btop rewrites it on exit)
  home.activation.btopConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    BTOP_DIR="$HOME/.config/btop"
    mkdir -p "$BTOP_DIR/themes"
    SRC="${../../../dotfiles/btop/.config/btop/btop.conf}"
    if [ ! -f "$BTOP_DIR/btop.conf" ]; then
      cp "$SRC" "$BTOP_DIR/btop.conf"
    fi
  '';
}
