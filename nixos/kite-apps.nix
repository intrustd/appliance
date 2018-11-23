{ pkgs, config, ... }:

let buildBundle = module:
      import ../../stork-cpp/nix/build-bundle.nix {
        inherit pkgs;
	system = pkgs.stdenv.targetPlatform.system;
	kite-app-module = module;
      };
in
{
  services.kite.applications."kite+app://flywithkite.com/admin" =
    buildBundle ../../stork-cpp/apps/admin/kite.nix;
}
