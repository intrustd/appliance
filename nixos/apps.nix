{ pkgs, config, ... }:

let buildBundle = module:
      (import (pkgs.intrustd.nix + /build-bundle.nix) {
         systems = builtins.listToAttrs [ { name = pkgs.hostPlatform.config;
                                            value = pkgs; } ];
         app-module = module + /app.nix;
        pure-build = true;
        }).manifest;

   admin-app = pkgs.intrustd-static.src;
in
{
  services.intrustd.applications."admin.intrustd.com" =
    buildBundle admin-app;
}
