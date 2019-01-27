{ stdenv, jq, curl, lib, pkgs, ... }:

stdenv.mkDerivation {
  name = "update-intrustd-appliance";

  src = ./update.sh;

  unpackPhase = ''
    cp $src ./update-intrustd-appliance.sh
  '';

  buildPhase = ''
     substituteAllInPlace update-intrustd-appliance.sh
  '';

  installPhase = ''
     mkdir -p $out/bin/
     cp ./update-intrustd-appliance.sh $out/bin/update-intrustd-appliance
     chmod +x $out/bin/update-intrustd-appliance
  '';

  jq = "${lib.getBin jq}/bin/jq";
  curl = "${lib.getBin curl}/bin/curl";
  inherit (pkgs) runtimeShell;
}
