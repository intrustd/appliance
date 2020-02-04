{ stdenv, intrustd, fetchFromGitHub, pkgs, nodejs-8_x, ... }:

let admin-app = fetchFromGitHub {
      owner = "intrustd";
      repo = "admin";
      rev = "e4750ebd06db7703802ecccdb1a33b04aaaa8fdd";
      sha256 = "0lkv65nil4q4srmd5wldkrppxbgnk996dv7vkd14l559zx9cbpw3";
    };

    nodeDeps = (((import (admin-app + /js) { pkgs = pkgs.buildPackages; nodejs = pkgs.buildPackages."nodejs-8_x"; }).shell.override { bypassCache = true; }).nodeDependencies);
in stdenv.mkDerivation {
  name = "intrustd-static";

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
