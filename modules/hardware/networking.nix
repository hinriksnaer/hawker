{ pkgs, config, ... }:

{
  networking.networkmanager.enable = true;
  users.users.${config.hawker.username}.extraGroups = [ "networkmanager" ];
}
