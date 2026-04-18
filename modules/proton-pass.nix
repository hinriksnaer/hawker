{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    proton-pass-cli
    gnome-keyring
  ];

  # Keyring for secret storage (used by pass-cli for session credentials)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
}
