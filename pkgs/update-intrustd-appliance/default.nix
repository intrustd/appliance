{ stdenv, jq, curl, nix-fetch,
  runit, util-linux, intrustdDir ? "/var/intrustd",
  lib, pkgs, ... }:

stdenv.mkDerivation {
  name = "update-intrustd-appliance";

  src = ./src;

  unpackPhase = ''
    cp $src/update.sh ./update-intrustd-appliance.sh
    cp $src/intrustd-update-server.sh ./intrustd-update-server.sh
  '';

  buildPhase = ''
     substituteAllInPlace update-intrustd-appliance.sh
     substituteAllInPlace intrustd-update-server.sh
  '';

  installPhase = ''
     mkdir -p $out/bin/
     mkdir -p $out/share/intrustd
     cp ./update-intrustd-appliance.sh $out/bin/update-intrustd-appliance
     cp ./intrustd-update-server.sh $out/share/intrustd/intrustd-update-server
     chmod +x $out/bin/update-intrustd-appliance
     chmod +x $out/share/intrustd/intrustd-update-server
  '';

  jq = "${lib.getBin jq}/bin/jq";
  curl = "${lib.getBin curl}/bin/curl";
  nixFetch = "${lib.getBin nix-fetch}/bin/nix-fetch";
  runitInit = "${lib.getBin runit}/bin/runit-init";
  flock = "${lib.getBin util-linux}/bin/flock";
  inherit intrustdDir;
  inherit (pkgs) runtimeShell;
}
