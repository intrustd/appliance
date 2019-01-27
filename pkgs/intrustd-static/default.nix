{ stdenv, intrustd, fetchFromGitHub, pkgs, nodejs-8_x, ... }:

let admin-app = fetchFromGitHub {
      owner = "intrustd";
      repo = "admin";
      rev = "973cc7d0f3a37c6bf029f39b0c0b897226a4b024";
      sha256 = "0qj03324nksf9xa14dyl8hwcgxc9pz3rdvqc9iamn5jjrkz4jwgd";
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
