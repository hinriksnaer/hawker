{ pkgs, config, lib, ... }:

let
  hasNvidia = builtins.hasAttr "nvidia" config.hardware && config.hardware.nvidia ? modesetting && config.hardware.nvidia.modesetting.enable or false;
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
