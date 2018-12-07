{ pkgs, config, ... }:

let buildBundle = module:
      import (pkgs.kite.nix + /build-bundle.nix) {
        systems = builtins.listToAttrs [ { name = pkgs.hostPlatform.config;
                                           value = pkgs; } ];
	kite-app-module = module + /kite.nix;
        pure-build = true;
      };

   admin-app = pkgs.kite-static.src;
in
{
  services.kite.applications."admin.flywithkite.com" =
    buildBundle admin-app;
}
