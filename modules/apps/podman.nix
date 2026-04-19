{ pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;  # docker CLI alias
    defaultNetwork.settings.dns_enabled = true;
  };

  # Rootless podman
  security.unprivilegedUsernsClone = true;

  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
