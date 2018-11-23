let defaultPkgs = ./nixpkgs;

in { platform ? "odroid-hc2", nixpkgs-path ? defaultPkgs, pkgRev ? "ci" }:

let system = builtins.getAttr platform (import ./systems.nix);

    overrides = pkgs: rec {
      libgpgerror = pkgs.libgpgerror.overrideDerivation (oldAttrs: {
        postPatch = ''
          echo "Coping file"
          cp src/syscfg/lock-obj-pub.arm-unknown-linux-gnueabi.h src/syscfg/lock-obj-pub.arm-unknown-linux-musleabihf.h
          cp src/syscfg/lock-obj-pub.arm-unknown-linux-gnueabi.h src/syscfg/lock-obj-pub.linux-musleabihf.h
        '';
      });
      xorg = pkgs.xorg.overrideScope' (selfXorg: superXorg: {
        libpciaccess = superXorg.libpciaccess.overrideDerivation (oldAttrs: {
           patches = if builtins.hasAttr "patches" oldAttrs then oldAttrs.patches else [] ++
             pkgs.stdenv.lib.optional pkgs.targetPlatform.isAarch32 ./pkgs/libpciaccess/0001-musl-arm.patch;
        });
      });
    };

    versionModule = {
      system.nixos.versionSuffix = "kite";
      system.nixos.revision = pkgRev;
    };

    evalConfig = import (nixpkgs-path + /nixos/lib/eval-config.nix);
    systemConfig = { module, system, ... }:
      (evalConfig {
         inherit system;
         modules = [ module versionModule ];
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
                   ./nixos/profiles/minimal.nix ];
       config = {
         kite = { inherit platform; };
         nixpkgs.crossSystem = system;
         nixpkgs.overlays = [ (super: overrides) ];
         nixpkgs.pkgs = (import nixpkgs-path {
          crossSystem = config.nixpkgs.crossSystem;
          overlays = config.nixpkgs.overlays; });
       };
     };
     system = system.config;
  };

  sdCard = systemImg.config.system.build.sdImage;
  initialRamdisk = systemImg.config.system.build.initialRamdisk;

  kernel = systemImg.config.boot.kernelPackages.kernel;

  config= systemImg.config;
  baseSystem = systemImg.config.system.build.toplevel;

  diskImage = import (nixpkgs-path + /nixos/lib/make-disk-image.nix) {
    lib = config.nixpkgs.pkgs.lib;
    pkgs = import <nixpkgs> {};
    inherit config;
    format = "qcow2";
    diskSize = "2048";
    label = "NIXOS_SD";
  };
}
