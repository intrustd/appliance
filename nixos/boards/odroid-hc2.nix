{ config, lib, pkgs, ... }:
let sd-positions = with lib; {
      signed-bl1-position = mkDefault 1;
      bl2-position = mkDefault 31;
      uboot-position = mkDefault 63;
      tzsw-position = mkDefault 1503;
      env-position = mkDefault 2015;
      env-size = 32;
    };

    mmc-positions = with lib; {
      signed-bl1-position = mkDefault 0;
      bl2-position = mkDefault 30;
      uboot-position = mkDefault 62;
      tzsw-position = mkDefault 1502;
      env-position = mkDefault 2015;
      env-size = 32;
    };

    baseSystem = config.system.build.toplevel;
    initialRamdisk = config.system.build.initialRamdisk;

    buildBootIni = pkgs: pkgs.substituteAll {
      src = ./build-boot-ini.sh;
      isExecutable = true;
      path = with pkgs; [ coreutils gnused gnugrep ];
      inherit (pkgs) bash;
      inherit (config.boot) kernelParams;
      board = "exynos5422-odroidxu4";
    };

    bootIni = pkgs.writeText "boot.ini" ''
      ODROIDXU-UBOOT-CONFIG

      setenv initrd_high "0xffffffff"
      setenv fdt_high "0xffffffff"

      setenv ddr_freq 825

      setenv bootrootfs "console=tty1 console=ttySAC2,115200n8 root=/dev/mmcblk1p2 rootwait rw systemConfig=${baseSystem} init=${baseSystem}/init"

      fatload mmc 0:1 0x40008000 /nixos/${builtins.baseNameOf config.boot.kernelPackages.kernel}-uImage
      fatload mmc 0:1 0x42000000 /nixos/${builtins.baseNameOf initialRamdisk}-initrd
      fatload mmc 0:1 0x44000000 /nixos/${builtins.baseNameOf config.boot.kernelPackages.kernel}-dtbs/exynos5422-odroidxu4.dtb

      fdt addr 0x44000000

      dmc ${"\${ddr_freq}"}

      setenv bootargs "${"\${bootrootfs}"} s5p_mfc.mem=16M"

      bootm 0x40008000 0x42000000 0x44000000 ${"\${bootargs}"}
    '';
in {
  options = with lib; {
    boot.boards.odroid-hc2.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Odroid HC2 for boot";
    };

    boot.boards.odroid-hc2.mode = mkOption {
      type = types.enum [ "sd" "mmc" ];
      description = "Whether to boot from sd or mmc";
      default = "sd";
    };

    boot.boards.odroid-hc2.fw-offsets = {
      signed-bl1-position = mkOption {
        type = types.int;
        description = "Position of signed bl1.HardKernel on SD/MMC image (in blocks)";
      };

      bl2-position = mkOption {
        type = types.int;
        description = "Position of bl2.HardKernel on SD/MMC image (in blocks)";
      };

      uboot-position = mkOption {
        type = types.int;
        description = "Position of u-boot binary on SD/MMC image (in blocks)";
      };

      tzsw-position = mkOption {
        type = types.int;
        description = "Position of TZSW.HardKernel on SD/MMC image (in blocks)";
      };

      env-position = mkOption {
        type = types.int;
        description = "Position of u-boot environment";
      };

      env-size = mkOption {
        type = types.int;
        description = "Size of u-boot environment in blocks";
      };
    };
  };

  config =
    let basicOdroid =
          lib.mkIf config.boot.boards.odroid-hc2.enable {
            boot.loader.grub.enable = false;
#    boot.loader.generic-extlinux-compatible.enable = true;

            boot.boards.odroid-hc2.fw-offsets =
              if config.boot.boards.odroid-hc2.mode == "sd"
              then sd-positions else mmc-positions;

            services.mingetty.manualConsole = {
              tty1 = { type = "vt102";  };
              ttySAC2 = { type = "vt102"; };
            };

            system.build.installBootLoader = "${buildBootIni pkgs}";
            system.build.loader.id = "intrustd-odroid";

            boot.initrd.checkJournalingFS = false;
            boot.kernelPackages = pkgs.linuxPackages_custom rec {
              version = "4.14.78"; # 77 for bak

              src = pkgs.fetchFromGitHub {
                owner = "hardkernel";
                repo = "linux";
                rev = "c3e379003dd5272b48f2676c21abf0493aac4e33";
                sha256 = "0139qciaf1vlz41s9idjbcx20c1svrp1l7qaazfkwfx52ghb4pvv";
        #        url = "mirror://kernel/linux/kernel/v4.x/linux-${version}.tar.xz";
        #        sha256 = "1y567wkr4p7hywq3pdw06yc4hi16rp1vkx764wzy5nyajkhz95h4";
              };

              configfile = ./odroid-hc-config.config;

              kernelPatches = [
                { name = "0001"; patch = ./odroid-hc2/0001-sctp-factor-out-stream-out-allocation.patch;        }
                { name = "0002"; patch = ./odroid-hc2/0002-sctp-factor-out-stream-in-allocation.patch;	       }
                { name = "0003"; patch = ./odroid-hc2/0003-sctp-introduce-struct-sctp_stream_out_ext.patch;    }
                { name = "0004"; patch = ./odroid-hc2/0004-sctp-introduce-sctp_chunk_stream_no.patch;	       }
                { name = "0005"; patch = ./odroid-hc2/0005-sctp-introduce-stream-scheduler-foundations.patch;  }
                { name = "0006"; patch = ./odroid-hc2/0006-sctp-add-sockopt-to-get-set-stream-scheduler.patch; }
                { name = "0007"; patch = ./odroid-hc2/0007-sctp-add-sockopt-to-get-set-stream-scheduler-paramet.patch; }
                { name = "0008"; patch = ./odroid-hc2/0008-sctp-introduce-priority-based-stream-scheduler.patch;       }
                { name = "0009"; patch = ./odroid-hc2/0009-sctp-introduce-round-robin-stream-scheduler.patch;	       }
                { name = "0010"; patch = ./odroid-hc2/0010-sctp-make-array-sctp_sched_ops-static.patch;		       }
                { name = "0011"; patch = ./odroid-hc2/0011-net-sctp-Convert-timers-to-use-timer_setup.patch;	       }
                { name = "0012"; patch = ./odroid-hc2/0012-sctp-fix-error-return-code-in-sctp_send_add_streams.patch;  }
                { name = "0013"; patch = ./odroid-hc2/0013-sctp-do-not-free-asoc-when-it-is-already-dead-in-sct.patch; }
                { name = "0014"; patch = ./odroid-hc2/0014-sctp-use-the-right-sk-after-waking-up-from-wait_buf-.patch; }
                { name = "0015"; patch = ./odroid-hc2/0015-sctp-check-stream-reset-info-len-before-making-recon.patch; }
                { name = "0016"; patch = ./odroid-hc2/0016-sctp-use-sizeof-__u16-for-each-stream-number-length-.patch; }
                { name = "0017"; patch = ./odroid-hc2/0017-sctp-only-allow-the-out-stream-reset-when-the-stream.patch; }

              ];
            };

            system.activationScripts.makeBootDir = {
               text = ''
                 mkdir -p /boot
               '';
               deps = [ "specialfs" ];
            };

            boot.kernelParams = [
              "net.ifnames=1" # Predictable network interface names
              "usb-storage.quirks=152d:0578:u" # Disable UAS on the USB3<->SATA interface
            ];

            nixpkgs.overlays = [ (self: super: {
              dhcpcd = super.dhcpcd.override { udev = null; };
            }) ];

            swapDevices = [
              { device = "/dev/sda1"; }
            ];

            fileSystems.intrustd = {
              device = "/dev/sda2";
              fsType = "btrfs";
              mountPoint = "/mnt/intrustd";
              noCheck = true;
            };

            services.intrustd.stateDir = "/mnt/intrustd/data";
          };

        sdImageOpts = lib.mkIf (config.intrustd.medium == "sd") {
          sdImage = {
            populateBootCommands =
              let offsets = config.boot.boards.odroid-hc2.fw-offsets;
              in ''
                echo "This should populate ODROID binary blobs commands"
                cp ${pkgs.ubootOdroidXU4}/u-boot-dtb.bin $NIX_BUILD_TOP/boot
                target="$NIX_BUILD_TOP/boot" ${buildBootIni pkgs.buildPackages} ${baseSystem}

                # Write the binary blobs
                echo "Fusing bl1.HardKernel"
                dd conv=notrunc if=${pkgs.odroid-xu4-firmware}/bl1.HardKernel of=$img seek=${builtins.toString offsets.signed-bl1-position}

                echo "Fusing bl2.HardKernel"
                dd conv=notrunc if=${pkgs.odroid-xu4-firmware}/bl2.HardKernel of=$img seek=${builtins.toString offsets.bl2-position}

                echo "Fusing u-boot"
                dd conv=notrunc if=$NIX_BUILD_TOP/boot/u-boot-dtb.bin of=$img seek=${builtins.toString offsets.uboot-position}

                echo "Fusing TZSW firmware"
                dd conv=notrunc if=${pkgs.odroid-xu4-firmware}/tzsw.HardKernel of=$img seek=${builtins.toString offsets.tzsw-position}

                echo "Erase u-boot environment"
                dd conv=notrunc if=/dev/zero of=$img seek=${builtins.toString offsets.env-position} bs=512 count=${builtins.toString offsets.env-size}
              '';
          };
        };
     in lib.mkMerge [ sdImageOpts basicOdroid ];
}
