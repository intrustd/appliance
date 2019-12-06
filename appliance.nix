let defaultPkgs = ./nixpkgs;

in { platform ? "odroid-hc2", nixpkgs-path ? defaultPkgs, pkgRev ? "ci",
     hydraJobUrl ? null }:

let system = builtins.getAttr platform (import ./systems.nix);

    evalConfig = import (nixpkgs-path + /nixos/lib/eval-config.nix);
    systemConfig = { module, system, medium, ... }:
      (evalConfig {
         inherit system;
         modules = [ module ];
         extraArgs = { inherit medium nixpkgs-path; };
       });

in rec {
  nixos = import (nixpkgs-path + /nixos/release.nix) { nixpkgs = import nixpkgs-path; };

  systemImg = medium: systemConfig {
     inherit medium;
     module = { config, ... }: {
       imports = [ ./sd-image.nix
                   ./virtualbox-image.nix
                   ./nixos/boot.nix
                   ./nixos/kernel.nix
                   ./nixos/configuration.nix
                   ./nixos/profiles/minimal.nix ];
       config = {
         intrustd = { inherit platform;
                      updates.hydraJobUrl = hydraJobUrl; };
         nixpkgs.crossSystem = system;
         nixpkgs.pkgs = (import nixpkgs-path {
          crossSystem = config.nixpkgs.crossSystem;
          overlays = config.nixpkgs.overlays; });

         system.nixos.versionSuffix = "-intrustd";
         system.nixos.revision = pkgRev;

         sdImage.enable = medium == "sd";
         virtualbox.enable = medium == "vbox";
       };
     };
     system = system.config;
  };

  sdSystemImg = systemImg "sd";
  vboxSystemImg = systemImg "vbox";

  sdCard = sdSystemImg.config.system.build.sdImage;
  initialRamdisk = sdSystemImg.config.system.build.initialRamdisk;

  kernel = sdSystemImg.config.boot.kernelPackages.kernel;

  pkgs =  config.nixpkgs.pkgs;

  config = sdSystemImg.config;
  baseSystem = sdSystemImg.config.system.build.toplevel;

  virtualBoxImage = vboxSystemImg.config.system.build.virtualBoxOVA;

  diskImage = import (nixpkgs-path + /nixos/lib/make-disk-image.nix) {
    lib = config.nixpkgs.pkgs.lib;
    pkgs = import <nixpkgs> {};
    inherit config;
    format = "qcow2";
    diskSize = "2048";
    label = "NIXOS_SD";
  };

  buildApp = import ./nixos/build-bundle.nix config.nixpkgs.pkgs;
}
