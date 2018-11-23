{ platform ? "odroid-hc2" }: # nixpkgs ? }:

let pkgRev = "8895ae2a62c72c63892a3ad4d38bf2a621ecacac";

    nixpkgs = import ./nixpkgs;

    system = builtins.getAttr platform (import ./systems.nix);
    ourPkgs = nixpkgs {};
    crossPkgs = (nixpkgs { crossSystem = system;
                           config.packageOverrides = overrides; });
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

    evalConfig = import ./nixpkgs/nixos/lib/eval-config.nix;
    systemConfig = { module, system, ... }:
      (evalConfig {
         inherit system;
         modules = [ module versionModule ];
       });
    makeSdImage = args:
      with import ./nixpkgs { inherit system; };
       system.config.system.build.sdImage;

in rec {
  pkgs = crossPkgs;
  stdenv = crossPkgs.stdenv;

  nixos = import ./nixpkgs/nixos/release.nix { inherit nixpkgs; };

  systemImg = systemConfig {
     module = { config, ... }: {
       imports = [ ./nixpkgs/nixos/modules/installer/cd-dvd/sd-image.nix
                   ./nixos/boot.nix
                   ./nixos/kernel.nix
                   ./nixos/configuration.nix
                   ./nixos/profiles/minimal.nix ];
       config = {
         kite = { inherit platform; };
         nixpkgs.crossSystem = system;
         nixpkgs.overlays = [ (pkgs.lib.const overrides) ];
         nixpkgs.pkgs = (nixpkgs { crossSystem = config.nixpkgs.crossSystem;
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

  diskImage = import ./nixpkgs/nixos/lib/make-disk-image.nix {
    lib = config.nixpkgs.pkgs.lib;
    pkgs = import <nixpkgs> {};
    inherit config;
    format = "qcow2";
    diskSize = "2048";
    label = "NIXOS_SD";
  };

  gdb = pkgs.buildPackages.gdb;
  ebtables = pkgs.ebtables;

  pycffi = pkgs.python36.withPackages (ps: with ps; [ cffi ]);
}
