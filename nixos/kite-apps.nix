{ pkgs, config, ... }:

let buildBundle = module:
      import (pkgs.kite.nix + /build-bundle.nix) {
        inherit pkgs;
	system = pkgs.stdenv.targetPlatform.system;
	kite-app-module = module + /kite.nix;
        pure-build = true;
      };

   admin-app = pkgs.fetchFromGitHub {
     owner = "kitecomputing";
     repo = "admin";
     rev = "8ebf4609518925c5fb73fb33a94c022a419a6118";
     sha256 = "17gzigkyqxfzv8vcqjf8dlwzz6rf4qklji4aq8yjngx11ms4vlkf";
   };
in
{
  services.kite.applications."kite+app://flywithkite.com/admin" =
    buildBundle admin-app;
}
