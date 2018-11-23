{ lib, config, pkgs, ... }:

with lib;

{
  options = {
    boot.boards.qemu-x86_64.enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.boot.boards.qemu-x86_64.enable {

    boot.initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_blk" "virtio_scsi" "9p" "9pnet_virtio" ];
    boot.initrd.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" ];
#    security.rngd.enable = false;

    boot.initrd.postDeviceCommands =
      ''
        # Set the system time from the hardware clock to work around a
        # bug in qemu-kvm > 1.5.2 (where the VM clock is initialised
        # to the *boot time* of the host).
        hwclock -s
      '';

    services.mingetty.manualConsole = {
      ttyS0 = { type = "vt102";  };
    };

    boot.loader.grub.enable = false;
    boot.kernelModules = [ "sctp" "tun" "ebtables" "br_netfilter" ];
#    boot.loader.grub.device = "/dev/xvda";
#    boot.loader.grub.efiSupport = false;
#    boot.loader.grub.version = 1;

    system.build.installBootloader = "echo 'Kite: No bootloader for qemu targets'; true";
    boot.kernelPackages = pkgs.linuxPackages_4_18;
  };
}
