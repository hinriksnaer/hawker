# Container management CLI (hawker-container command).
# Wraps containers/hawker-container.sh with runtime dependencies.
# Imported by roles/core.nix so the command is available on all hosts
# (deploy and manage remote dev containers from any machine).
{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "hawker-container";
      runtimeInputs = with pkgs; [ rsync openssh git nix coreutils ];
      text = builtins.readFile ./hawker-container.sh;
      # SC2029: ssh command expands variables client-side (intentional)
      # SC2016: single-quoted strings don't expand (intentional for ssh)
      excludeShellChecks = [ "SC2029" "SC2016" ];
    })
  ];
}
