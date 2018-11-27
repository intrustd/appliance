{ pkgs, config, ... }:

let buildBundle = module:
      import (pkgs.kite.nix + /build-bundle.nix) {
        inherit pkgs;
        systems = builtins.listToAttrs [ { name = pkgs.hostPlatform.config;
                                           value = pkgs; } ];
	kite-app-module = module + /kite.nix;
        pure-build = true;
      };

   admin-app = pkgs.kite-static.src;
in
{
  services.kite.applications."kite+app://flywithkite.com/admin" =
    buildBundle admin-app;
}
