{ pkgs, stdenv, cmake, uriparser, lksctp-tools, curl, fetchFromGitHub
, pkgconfig, zlib, openssl_1_1, uthash, check, enableVerboseWebrtc ? false, enableDebug ? false }:

stdenv.mkDerivation rec {
   name = "intrustd-${version}";
   version = "0.1.0";

   src = fetchFromGitHub {
     owner = "intrustd";
     repo = "daemon";
     rev = "216c6606721c63faa9923b94f643d4be85578ab1";
     sha256 = "1vb6d0s0rni240pv1gbigdb0n1h4fj1lrwk92cb43ql7rfgysfyj";
   };

   nativeBuildInputs = [ cmake pkgconfig ];
   buildInputs = [ uriparser lksctp-tools curl openssl_1_1 uthash check ];

   outputs = [ "out" "flockd" "applianced" "appliancectl" "nix" ];

#   configurePhase = ''
#     cmake -DCMAKE_BUILD_TYPE=Release .
#   '';

   cmakeFlags = stdenv.lib.concatStringsSep " " (stdenv.lib.optional enableVerboseWebrtc "-DWEBRTC_DEBUG=ON" ++
                                                 stdenv.lib.optional enableDebug "-DCMAKE_BUILD_TYPE=Debug");
   dontStrip=true;

   installPhase = ''
     mkdir -p $flockd/bin
     mkdir -p $applianced/bin
     mkdir -p $appliancectl/bin
     mkdir -p $out

     cp -R bin $out/bin

     mv bin/flockd $flockd/bin/flockd

     mv bin/appliancectl $appliancectl/bin/appliancectl

     mv bin/applianced $applianced/bin/applianced
     mv bin/app-instance-init $applianced/bin/app-instance-init
     mv bin/persona-init $applianced/bin/persona-init
     mv bin/webrtc-proxy $applianced/bin/webrtc-proxy

     cp -R $src/nix $nix
   '';

   meta = with stdenv.lib; {
     description = "Intrustd daemons";
     homepage = http://intrustd.com/;
     licenses = licenses.mit;
     platforms = platforms.linux;
   };
}
