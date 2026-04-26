{ pkgs, config, ... }:

let
  agentSocket = "/home/${config.hawker.username}/.ssh/proton-pass-agent.sock";

  # Wrap pass-cli to work around NixOS kernel keyring group permissions bug.
  # NixOS creates the session keyring with gid 65534 (nogroup) instead of the
  # user's primary group, causing EACCES when pass-cli tries to store keys.
  # `keyctl new_session` replaces the current process's session keyring in-place
  # (unlike `keyctl session -` which execs into a new one), so the keyring persists
  # across all pass-cli invocations within the same shell session.
  # Upstream: https://github.com/NixOS/nixpkgs/issues/497155
  pass-cli-wrapped = pkgs.writeShellScriptBin "pass-cli" ''
    ${pkgs.keyutils}/bin/keyctl new_session >/dev/null 2>&1 || true
    exec ${pkgs.proton-pass-cli}/bin/pass-cli "$@"
  '';

  # Helper to check and set up the Proton Pass SSH agent connection.
  pass-ssh-setup = pkgs.writeShellScriptBin "pass-ssh-setup" ''
    SOCK="${agentSocket}"

    echo "SSH_AUTH_SOCK=$SOCK"

    if [ ! -S "$SOCK" ]; then
      echo "Socket missing. Start Proton Pass desktop app to create it."
      exit 1
    fi

    if SSH_AUTH_SOCK="$SOCK" ssh-add -l >/dev/null 2>&1; then
      echo "Agent OK. Keys:"
      SSH_AUTH_SOCK="$SOCK" ssh-add -l
    else
      echo "Socket exists but agent not responding."
      echo "Try restarting Proton Pass, or remove stale socket:"
      echo "  rm $SOCK"
      exit 1
    fi
  '';
in
{
  environment.systemPackages = [
    pass-cli-wrapped
    pass-ssh-setup
    pkgs.proton-pass  # Desktop app (unlocks shared vaults)
    pkgs.keyutils     # keyctl for Linux kernel keyring
  ];

  # Point SSH_AUTH_SOCK at the Proton Pass agent socket.
  # The socket is created when Proton Pass launches; SSH commands
  # will work once the app is running.
  environment.sessionVariables.SSH_AUTH_SOCK = agentSocket;

  # gnome-keyring for general secret storage (other apps, not pass-cli)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # Disable GCR SSH agent -- Proton Pass manages SSH keys instead.
  # Without this, GCR claims SSH_AUTH_SOCK and SSH never reaches Proton Pass.
  systemd.user.sockets.gcr-ssh-agent.enable = false;
}
