# NixOS VM integration test
# Boots a minimal system and verifies:
#   1. System boots successfully
#   2. User account is created with correct name from settings.nix
#   3. gnome-keyring-daemon is available and PAM hooks are set
#   4. Session variables (HAWKER_USER) are set
#   5. Theme engine scripts are functional
#   6. pass-cli wrapper pattern works (keyctl session fix)
#
# Run: nix build .#checks.x86_64-linux.vm-integration --print-build-logs
# Requires KVM (won't work in unprivileged containers).
{ pkgs, settings }:

let
  inherit (settings) username;

  # Mock pass-cli wrapper to verify the keyctl session pattern without
  # pulling in the unfree proton-pass-cli package.
  mock-pass-cli = pkgs.writeShellScriptBin "pass-cli" ''
    exec ${pkgs.keyutils}/bin/keyctl session - echo "pass-cli-mock: $@"
  '';
in
pkgs.testers.nixosTest {
  name = "hawker-integration";

  nodes.machine = { config, pkgs, lib, ... }: {
    # Minimal user setup (mirrors base.nix without nixpkgs.config)
    users.users.${username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      shell = pkgs.fish;
    };
    programs.fish.enable = true;
    environment.sessionVariables.HAWKER_USER = username;

    # gnome-keyring (mirrors proton-pass.nix without unfree dep)
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.login.enableGnomeKeyring = true;
    environment.systemPackages = [ mock-pass-cli pkgs.keyutils ];

    virtualisation.memorySize = 2048;

    # Deploy theme scripts and mock theme
    system.activationScripts.testSetup = ''
      mkdir -p /home/${username}/.local/bin
      cp -r ${../dotfiles/scripts/.local/bin}/* /home/${username}/.local/bin/
      chmod -R +x /home/${username}/.local/bin/

      mkdir -p /home/${username}/.local/share/hawker/themes/test-theme/backgrounds
      echo '# test' > /home/${username}/.local/share/hawker/themes/test-theme/hyprland.conf
      echo '# test' > /home/${username}/.local/share/hawker/themes/test-theme/btop.theme
      touch /home/${username}/.local/share/hawker/themes/test-theme/backgrounds/wall.png

      mkdir -p /home/${username}/.config/hypr
      mkdir -p /home/${username}/.config/hawker/current
      mkdir -p /home/${username}/.config/btop/themes
      touch /home/${username}/.config/hypr/active-theme.conf

      chown -R ${username}:users /home/${username}
    '';
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # 1. User account exists with correct shell
    machine.succeed("id ${username}")
    machine.succeed("getent passwd ${username} | grep -q fish")

    # 2. HAWKER_USER session variable is configured
    machine.succeed("grep 'HAWKER_USER' /etc/set-environment")

    # 3. gnome-keyring is available
    machine.succeed("which gnome-keyring-daemon")

    # 4. PAM gnome-keyring hooks are in login config
    machine.succeed("grep -q gnome_keyring /etc/pam.d/login")

    # 5. pass-cli wrapper uses keyctl session fix
    result = machine.succeed("cat $(which pass-cli)")
    assert "keyctl" in result, f"pass-cli wrapper missing keyctl: {result}"

    # 6. keyctl session wrapper actually works
    machine.succeed("su - ${username} -c 'pass-cli test'")

    # 7. Theme list works
    result = machine.succeed(
        "su - ${username} -c '"
        "export HAWKER_PATH=/home/${username}/.local/share/hawker; "
        "export PATH=/home/${username}/.local/bin:$PATH; "
        "fish /home/${username}/.local/bin/hawker-theme-list'"
    )
    assert "test-theme" in result, f"Expected test-theme in output, got: {result}"

    # 8. Theme set terminal works end-to-end
    machine.succeed(
        "su - ${username} -c '"
        "export HAWKER_PATH=/home/${username}/.local/share/hawker; "
        "export PATH=/home/${username}/.local/bin:$PATH; "
        "fish /home/${username}/.local/bin/hawker-theme-set-terminal test-theme'"
    )
    machine.succeed("test -L /home/${username}/.config/hawker/current/theme")
  '';
}
