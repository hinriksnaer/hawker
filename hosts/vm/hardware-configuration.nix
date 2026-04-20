# Placeholder -- replace with output of nixos-generate-config on the actual VM.
# For image builds, the disk-image module provides its own fileSystems.
{ lib, ... }:

{
  fileSystems."/" = lib.mkDefault {
    device = "/dev/vda1";
    fsType = "ext4";
  };

  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" "virtio_net" ];
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
}
