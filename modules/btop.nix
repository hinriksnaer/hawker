{ pkgs, config, ... }:

let
  btop-nvidia = pkgs.btop.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/btop \
        --prefix LD_LIBRARY_PATH : "${config.hardware.nvidia.package}/lib"
    '';
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
  });
in
{
  environment.systemPackages = [
    btop-nvidia
  ];
}
