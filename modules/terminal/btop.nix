{ pkgs, config, lib, ... }:

let
  hasNvidia = config.hardware.nvidia.modesetting.enable or false;
  btop-pkg = if hasNvidia then
    pkgs.btop.overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        wrapProgram $out/bin/btop \
          --prefix LD_LIBRARY_PATH : "${config.hardware.nvidia.package}/lib"
      '';
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
    })
  else
    pkgs.btop;
  username = config.hawker.username;
in
{
  environment.systemPackages = [ btop-pkg ];

  # btop rewrites its config on exit -- copy instead of symlink
  system.activationScripts.btopConfig = ''
    BTOP_DIR="/home/${username}/.config/btop"
    mkdir -p "$BTOP_DIR/themes"
    SRC="${../../dotfiles/btop/.config/btop/btop.conf}"
    if [ -f "$SRC" ]; then
      cp "$SRC" "$BTOP_DIR/btop.conf"
      chown -R ${username}:users "$BTOP_DIR"
    fi
  '';
}
