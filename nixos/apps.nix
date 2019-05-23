{ pkgs, config, ... }:

let buildBundle = import ./build-bundle.nix pkgs;

   admin-app = pkgs.intrustd-static.src;
in
{
  services.intrustd.applications."admin.intrustd.com" =
    buildBundle admin-app;
}
