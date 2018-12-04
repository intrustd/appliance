{ stdenv, cmake, pkgconfig, nix, boost, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "nix-fetch";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "kitecomputing";
    repo = "nix-fetch";
    rev = "664d32f4c19c0f8c9cf8a4f1a69370a861716554";
    sha256 = "0pcy42pxrwzbsmfs2wdlbm8rjwfz8bvc6yxmyiyqdzlpb87ghbji";
  };

  nativeBuildInputs = [ cmake pkgconfig ];
  buildInputs = [ nix.dev boost ];

  installPhase = ''
     mkdir -p $out/bin
     cp nix-fetch $out/bin/nix-fetch
  '';

  meta = with stdenv.lib; {
    description = "Advanced version of nix-copy-closure";
    homepage = http://flywithkite.com/;
    licenses = licenses.mit;
  };
}
