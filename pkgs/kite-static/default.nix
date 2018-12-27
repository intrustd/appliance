{ stdenv, kite, fetchFromGitHub, pkgs, nodejs-8_x, ... }:

let admin-app = fetchFromGitHub {
      owner = "kitecomputing";
      repo = "admin";
      rev = "5c8011c237a0ba9bd24fb29344f8b9fefb33275a";
      sha256 = "0l8w4w8a8b9pk48g7iikljaxylhym84bwsq740z7n77n8qpffrv6";
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
