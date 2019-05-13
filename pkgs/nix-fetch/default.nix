{ stdenv, cmake, pkgconfig, nix, boost, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "nix-fetch";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "intrustd";
    repo = "nix-fetch";
    rev = "bbfc95af2a18e519ae2a9d3192bbc84e09a338db";
    sha256 = "08wwjxcb11y24s37k6y42c8n3m5cchy53dq77c4mk9jkb4kcnz1a";
  };

  nativeBuildInputs = [ cmake pkgconfig ];
  buildInputs = [ nix.dev boost ];

  installPhase = ''
     mkdir -p $out/bin
     cp nix-fetch $out/bin/nix-fetch
  '';

  meta = with stdenv.lib; {
    description = "Advanced version of nix-copy-closure";
    homepage = http://intrustd.com/;
    licenses = licenses.mit;
  };
}
