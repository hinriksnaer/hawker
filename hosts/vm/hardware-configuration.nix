# Placeholder -- generate on the VM with:
#   nixos-generate-config --dir ~/hawker/hosts/vm/
{ lib, ... }:

{
  # KVM virtio disk
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/vda2";
    fsType = "vfat";
  };

  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" "virtio_net" ];
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
}
