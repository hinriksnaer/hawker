{ pkgs, config, lib, ... }:

let
  hasNvidia = builtins.elem "nvidia" config.services.xserver.videoDrivers;
in
{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;  # docker CLI alias
    defaultNetwork.settings.dns_enabled = true;
  };

  # NVIDIA container toolkit - suppress assertion for non-nvidia hosts
  hardware.nvidia-container-toolkit.suppressNvidiaDriverAssertion = !hasNvidia;

  # Rootless podman
  security.unprivilegedUsernsClone = true;

  users.users.${config.hawker.username}.extraGroups = [ "podman" ];

  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
