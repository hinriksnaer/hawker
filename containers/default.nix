# Docker-nixos base image, pinned via dockerTools.pullImage.
# Provides a full NixOS system with systemd, so nixos-rebuild works inside.
{ pkgs }:

(pkgs.dockerTools.pullImage {
  imageName = "ghcr.io/skiffos/docker-nixos";
  imageDigest = "sha256:c207c1f48492334b9ac6af92126c88df9ecd49684031a1b4d79a100f4f8c3e17";
  hash = "sha256-UVuMl+crYLYpfET3S8Jnfey3xCzqIJ9+2y5vlvCRIxo=";
  finalImageName = "docker-nixos";
  finalImageTag = "latest";
}).overrideAttrs (_: {
  __structuredAttrs = true;
  unsafeDiscardReferences.out = true;
})
