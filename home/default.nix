# Home Manager entry point.
# Receives hostname and settings from flake.nix, imports the
# matching profile which opts into shared modules.
{ hostname, settings }:

{ ... }:

{
  imports = [
    ./profiles/${hostname}.nix
  ];

  # Make settings available to all modules
  _module.args = {
    inherit settings hostname;
  };

  programs.home-manager.enable = true;
}
