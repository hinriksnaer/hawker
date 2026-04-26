{ pkgs, config, lib, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;  # docker CLI alias
    defaultNetwork.settings.dns_enabled = true;
  };

  # Rootless podman
  security.unprivilegedUsernsClone = true;

  users.users.${config.hawker.username}.extraGroups = [ "podman" ];

  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
