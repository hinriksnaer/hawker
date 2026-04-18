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
in
{
  environment.systemPackages = [ btop-pkg ];
}
