{ pkgs, ... }:

{ virtualbox = rec {
      memorySize = 2 * 1024;
      vmDerivationName = "intrustd-appliance-${pkgs.stdenv.hostPlatform.system}";
      vmName = "Intrustd Appliance ${pkgs.stdenv.hostPlatform.system}";
      vmFileName = "${vmDerivationName}.ova";
  };
}
