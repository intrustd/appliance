let defaultPkgs = ./nixpkgs;

in { platform ? "odroid-hc2", nixpkgs-path ? defaultPkgs, pkgRev ? "ci",
     hydraJobUrl ? null }:

let system = builtins.getAttr platform (import ./systems.nix);

    evalConfig = import (nixpkgs-path + /nixos/lib/eval-config.nix);
    systemConfig = { module, system, ... }:
      (evalConfig {
         inherit system;
         modules = [ module ];
       });
    makeSdImage = args:
      with import nixpkgs-path { inherit system; };
       system.config.system.build.sdImage;

in rec {
  nixos = import (nixpkgs-path + /nixos/release.nix) { nixpkgs = import nixpkgs-path; };

  systemImg = systemConfig {
     module = { config, ... }: {
       imports = [ (nixpkgs-path + /nixos/modules/installer/cd-dvd/sd-image.nix)
                   ./nixos/boot.nix
                   ./nixos/kernel.nix
                   ./nixos/configuration.nix
                   ./nixos/profiles/minimal.nix
                   ./virtualbox.nix ];
       config = {
         intrustd = { inherit platform;
                      updates.hydraJobUrl = hydraJobUrl; };
         nixpkgs.crossSystem = system;
         nixpkgs.pkgs = (import nixpkgs-path {
          crossSystem = config.nixpkgs.crossSystem;
          overlays = config.nixpkgs.overlays; });

         system.nixos.versionSuffix = "-intrustd";
         system.nixos.revision = pkgRev;
       };
     };
     system = system.config;
  };

  sdCard = systemImg.config.system.build.sdImage;
  initialRamdisk = systemImg.config.system.build.initialRamdisk;

  kernel = systemImg.config.boot.kernelPackages.kernel;

  pkgs =  config.nixpkgs.pkgs;

  config= systemImg.config;
  baseSystem = systemImg.config.system.build.toplevel;

  virtualBoxImage = systemImg.config.system.build.virtualBoxOVA;

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
