{ stdenv, kite, fetchFromGitHub, pkgs, nodejs-8_x, ... }:

let admin-app = fetchFromGitHub {
      owner = "kitecomputing";
      repo = "admin";
      rev = "d0d1bc6b819d8bc70e247aea68212faa57c42694";
      sha256 = "17030zi3lwj028jm6fdq5gk8d71rmv5h4xa42kdnfb969i2ml9g3";
    };

    nodeDeps = (((import (admin-app + /js) { pkgs = pkgs.buildPackages; nodejs = pkgs.buildPackages."nodejs-8_x"; }).shell.override { bypassCache = true; }).nodeDependencies);
in stdenv.mkDerivation {
  name = "kite-static";

  src = admin-app;

  nativeBuildInputs = [
      nodeDeps
      nodejs-8_x
  ];

  phases = [ "unpackPhase" "buildPhase" "installPhase" ];

  buildPhase = ''
    cd js
    ln -s ${nodeDeps}/lib/node_modules ./node_modules
    ln -s ${nodeDeps}/lib/package-lock.json ./package-lock.json
    webpack -p --progress --config webpack.local.js
  '';

  installPhase = ''
    cp -R ./dist-local $out/
  '';
}
