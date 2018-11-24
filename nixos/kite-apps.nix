{ pkgs, config, ... }:

let buildBundle = module:
      import (pkgs.kite.nix + /build-bundle.nix) {
        inherit pkgs;
	system = pkgs.stdenv.targetPlatform.system;
	kite-app-module = module + /kite.nix;
        pure-build = true;
      };

   admin-app = pkgs.kite-static.src;
in
{
  services.kite.applications."kite+app://flywithkite.com/admin" =
    buildBundle admin-app;
}
