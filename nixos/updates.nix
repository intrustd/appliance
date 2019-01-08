{ config, pkgs, lib, ... }:

let nixGcScript = pkgs.writeScript "nix-gc" ''
      exec ${config.nix.package.out}/bin/nix-collect-garbage
    '';

in {
  options = with lib; {
    kite.updates.hydraJobUrl = mkOption {
      type = types.nullOr types.string;
      description = "URL of the hydra job for this build";
      default = null;
    };
  };

  config = lib.mkMerge [
    {
      nixpkgs.overlays = [
        (self: super: {
          kite-update = self.callPackage ../pkgs/kite-update {};
         })
      ];

      nix.binaryCachePublicKeys = [ "cache.flywithkite.com-1:7JJMfk9Vl5tetCyL8TnGSmo6IMvJypOlLv4Y7huDvDQ=" ];
      nix.binaryCaches = lib.mkOverride 10 [ "https://hydra.flywithkite.com/cache" ];

      environment.systemPackages = [ pkgs.kite-update ];

      # We serialize a representation of the currently booted kernel and
      # initrd into this file. We can use it to determine if we need to
      # restart this device after an update by comparing
      # /run/booted-system/etc/kite-boot-info and
      # /run/current-system/etc/kite-boot-info.
      environment.etc."kite-boot-info".text = ''
      BOOTED_KERNEL=${config.boot.kernelPackages.kernel}
      BOOTED_INITRD=${config.system.build.initialRamdisk}
      '';

      environment.etc."kite/caches".text = ''
         https://hydra.flywithkite.com/cache cache.flywithkite.com-1:7JJMfk9Vl5tetCyL8TnGSmo6IMvJypOlLv4Y7huDvDQ=
      '';

      services.fcron.enable = true;
      services.fcron.systab = ''
      %hourly,mailto(kite),random(true),erroronlymail(true) * ${nixGcScript}
      '';

    }

    (lib.mkIf (config.kite.updates.hydraJobUrl != null) {
      environment.etc."kite-update-url".text = "${config.kite.updates.hydraJobUrl}";
    })
  ];
}
