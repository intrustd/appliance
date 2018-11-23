{pkgs, lib, ...}:
let baseLinux = pkgs.linux_4_18;

    kiteLinuxPackages = pkgs.linuxPackages_custom {
      inherit (baseLinux) version src;
      allowImportFromDerivation = false;
      configfile = pkgs.linuxConfig {
        makeTarget = "defconfig";
        src = baseLinux.src;
      };
    };
in
{
#  boot.kernelPackages = kiteLinuxPackages;

}
