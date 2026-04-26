# Bare-metal boot and system service configuration.
# Only imported by physical hosts (desktop, laptop), not containers.
{ lib, ... }:

{
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  services.dbus.enable = true;
}
