{ stdenv, intrustd, fetchFromGitHub, pkgs, nodejs-8_x, ... }:

let admin-app = fetchFromGitHub {
      owner = "intrustd";
      repo = "admin";
      rev = "8b6cf9db5c150808549a16509d399d4f3f5a9225";
      sha256 = "1sajjsxg78makq049jmway0nxgr3yb4n85rr9ykjdw1simxqj35n";
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
