{ stdenv, ... }:

stdenv.mkDerivation {
  name = "kite-static";

  src = ../../../stork-cpp/apps/admin/js/admin-local.tar.gz;

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p $out
    cp -R . $out/
  '';
}
