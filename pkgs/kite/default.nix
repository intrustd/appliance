{ pkgs, stdenv, cmake, uriparser, lksctp-tools, curl
, pkgconfig, zlib, openssl_1_1, uthash, check, enableVerboseWebrtc ? false }:

stdenv.mkDerivation rec {
   name = "kite-${version}";
   version = "0.1.0";

   src = ./../../../stork-cpp + "/deploy/kite-${version}.tar.bz2";

   nativeBuildInputs = [ cmake pkgconfig ];
   buildInputs = [ uriparser lksctp-tools curl openssl_1_1 uthash check ];

   outputs = [ "out" "flockd" "applianced" "appliancectl" ];

#   configurePhase = ''
#     cmake -DCMAKE_BUILD_TYPE=Release .
#   '';

   cmakeFlags = stdenv.lib.optionalString enableVerboseWebrtc "-DWEBRTC_DEBUG=ON";

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
   '';

   meta = with stdenv.lib; {
     description = "Kite binaries";
     homepage = http://flywithkite.com/;
     licenses = licenses.mit;
     platforms = platforms.linux;
   };
}
