# One Nix derivation per test file.
# Each shows as its own pass/fail in `nix flake check` and CI.
{ pkgs, src }:

let
  deps = with pkgs; [
    fish coreutils gnugrep gnused gawk findutils bash stow git
  ];

  mkTest = name: pkgs.runCommand "hawker-test-${name}" {
    nativeBuildInputs = deps;
  } ''
    cp -r ${src} ./repo
    chmod -R u+w ./repo
    chmod -R +x ./repo/scripts/
    patchShebangs ./repo/scripts/

    # Create symlinks without extensions so scripts find each other by name
    mkdir -p ./repo/.bin
    for f in ./repo/scripts/*.fish; do
      ln -s "$(realpath "$f")" "./repo/.bin/$(basename "$f" .fish)"
    done
    for f in ./repo/scripts/*.sh; do
      ln -s "$(realpath "$f")" "./repo/.bin/$(basename "$f" .sh)"
    done
    export PATH="./repo/.bin:$PATH"

    export REPO_DIR=./repo
    bash ./repo/tests/test-${name}.sh

    touch $out
  '';
in
{
  settings      = mkTest "settings";
  theme-list    = mkTest "theme-list";
  theme-current = mkTest "theme-current";
  theme-set     = mkTest "theme-set";
  theme-cycle   = mkTest "theme-cycle";
  bootstrap     = mkTest "bootstrap";
}
