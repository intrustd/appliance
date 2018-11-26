{ stdenv, jq, curl, lib, pkgs, ... }:

stdenv.mkDerivation {
  name = "kite-update";

  src = ./update.sh;

  unpackPhase = ''
    cp $src ./kite-update.sh
  '';

  buildPhase = ''
     substituteAllInPlace kite-update.sh
  '';

  installPhase = ''
     mkdir -p $out/bin/
     cp ./kite-update.sh $out/bin/kite-update
     chmod +x $out/bin/kite-update
  '';

  jq = "${lib.getBin jq}/bin/jq";
  curl = "${lib.getBin curl}/bin/curl";
  inherit (pkgs) runtimeShell;
}
