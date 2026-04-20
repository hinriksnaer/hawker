{ pkgs, config, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;  # docker CLI alias
    defaultNetwork.settings.dns_enabled = true;
  };

  # NVIDIA container support (CDI)
  hardware.nvidia-container-toolkit.enable = true;

  # Rootless podman
  security.unprivilegedUsernsClone = true;

  users.users.${config.hawker.username}.extraGroups = [ "podman" ];

  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
