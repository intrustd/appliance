{ pkgs, stdenv, ... }:

stdenv.mkDerivation {
  name = "odroid-xu4-firmware";

  src = pkgs.fetchFromGitHub {
    owner = "hardkernel";
    repo = "u-boot";
    rev = "88af53fbcef8386cb4d5f04c19f4b2bcb69e90ca";
    sha256 = "1v4kd01f9rxs68vipyckzc1q4d6hm3in69l9rbzbgzzda6vn8rf6";
  } + "/sd_fuse";

  buildPhase = "true";

  installPhase = ''
    mkdir -p $out/
    cp bl1.bin.hardkernel $out/bl1.HardKernel
    cp bl2.bin.hardkernel.720k_uboot $out/bl2.HardKernel
    cp tzsw.bin.hardkernel $out/tzsw.HardKernel
  '';

  meta = {
    homepage = https://github.com/hardkernel/u-boot;
    description = "Hardkernel XU4/HC2 binary blobs";
    license = stdenv.lib.licenses.unfreeRedistributableFirmware;
  };
}

#speed 115200 baud; line = 0;            
# min = 1; time = 5;                      
# ignbrk -brkint -icrnl -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke
