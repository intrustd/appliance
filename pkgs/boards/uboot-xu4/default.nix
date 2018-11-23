{ fetchFromGitHub, buildUBoot, stdenv }:

(buildUBoot rec {
   name = "uboot-${defconfig}-${version}";
   version = "2017.05";

   src = fetchFromGitHub {
     owner = "hardkernel";
     repo = "u-boot";
     rev = "88af53fbcef8386cb4d5f04c19f4b2bcb69e90ca";
     sha256 = "1v4kd01f9rxs68vipyckzc1q4d6hm3in69l9rbzbgzzda6vn8rf6";
   };

   patches = [];

   defconfig = "odroid-xu4_defconfig";
   extraMeta.platforms = [ "armv7l-linux" ];
   filesToInstall = [ "u-boot-dtb.bin" ];
}).overrideAttrs (old: {
  patches = [
#    ./pythonpath-2017.05.patch

  ];
})
