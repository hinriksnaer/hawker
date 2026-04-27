# VSCode Remote / Dev Containers compatibility for Nix-based OCI images.
#
# VSCode's check-requirements-linux.sh has a built-in NixOS bypass:
# it reads /etc/os-release and exits early when ID=nixos.
#
# Extensions and settings are declared here as plain Nix data and
# shipped as a devcontainer.metadata OCI label.  VSCode reads this
# label when attaching to a running container and auto-installs the
# listed extensions / applies the settings.
{ pkgs }:

let
  extensions = [
    "teabyii.ayu"
    "pkief.material-icon-theme"
    "ms-python.python"
    "ms-python.vscode-pylance"
  ];

  settings = {
    "extensions.verifySignature" = false;
  };
in
{
  # Inject into the etcDir derivation so check-requirements-linux.sh
  # detects NixOS and skips the ldconfig/glibc checks.
  etcSetup = ''
    echo "ID=nixos" > $out/etc/os-release
  '';

  # Symlink the dynamic linker to the standard FHS path so VSCode's
  # unpatched node binary can find it (runs in proot during image build).
  fakeRootSetup = ''
    mkdir -p /lib64
    ln -sf ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
  '';

  # OCI labels — VSCode reads devcontainer.metadata when attaching
  # and auto-installs extensions / applies settings.
  labels = {
    "devcontainer.metadata" = builtins.toJSON [{
      customizations.vscode = {
        inherit extensions settings;
      };
    }];
  };
}
