{ stdenv, cmake, pkgconfig, nix, boost, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "nix-fetch";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "intrustd";
    repo = "nix-fetch";
    rev = "656c53a6f8773cb52b0bb3816579351463d74afc";
    sha256 = "0cr4amcs0zfa5bfa5iakibd2fn7399kcdwmdzq1n8jn0gx9czkhf";
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
