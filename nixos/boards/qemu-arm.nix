{ pkgs, lib, config, ... }:

with lib;
let extlinux-conf-builder = import ../../nixpkgs/nixos/modules/system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix { inherit pkgs; };
in
{
  options = {
    boot.boards.qemu-arm.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.boot.boards.qemu-arm.enable {

    boot.initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_blk" "virtio_scsi" "9p" "9pnet_virtio" ];
    boot.initrd.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" ];
    security.rngd.enable = false;

    boot.initrd.postDeviceCommands =
      ''
        # Set the system time from the hardware clock to work around a
        # bug in qemu-kvm > 1.5.2 (where the VM clock is initialised
        # to the *boot time* of the host).
        hwclock -s
      '';

    sdImage.populateBootCommands = ''
        ${extlinux-conf-builder} -t 3 -c ${config.system.build.toplevel} -d $NIX_BUILD_TOP/boot
    '';
  };
}
