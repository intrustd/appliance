{ pkgs, stdenv, cmake, uriparser, lksctp-tools, curl, fetchFromGitHub
, pkgconfig, zlib, openssl_1_1, uthash, check, enableVerboseWebrtc ? false, enableDebug ? false }:

stdenv.mkDerivation rec {
   name = "intrustd-${version}";
   version = "0.1.0";

   src = fetchFromGitHub {
     owner = "intrustd";
     repo = "daemon";
     rev = "0ea6acd88ddac7c0efeef88f848e353e739e7769";
     sha256 = "1g63lwdlpszg9dglxgzmzs16lnry276m5bszdj6g2sfb6bvyr4f6";
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
