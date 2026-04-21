{ pkgs, ... }:

let
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
in
{
  environment.systemPackages = [
    pass-cli-wrapped
    pkgs.proton-pass  # Desktop app (unlocks shared vaults)
    pkgs.keyutils     # keyctl for Linux kernel keyring
  ];

  # gnome-keyring for general secret storage (other apps, not pass-cli)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # Disable GCR SSH agent -- Proton Pass manages SSH keys instead.
  # Without this, GCR claims SSH_AUTH_SOCK and SSH never reaches Proton Pass.
  systemd.user.sockets.gcr-ssh-agent.enable = false;
}
