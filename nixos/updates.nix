{ config, pkgs, lib, ... }:

let nixGcScript = pkgs.writeScript "nix-gc" ''
      exec ${config.nix.package.out}/bin/nix-collect-garbage
    '';

    intrustdDir = config.services.intrustd.stateDir;

in {
  options = with lib; {
    intrustd.updates.hydraJobUrl = mkOption {
      type = types.nullOr types.string;
      description = "URL of the hydra job for this build";
      default = null;
    };
  };

  config = lib.mkMerge [
    {
      nixpkgs.overlays = [
        (self: super: {
          update-intrustd-appliance = self.callPackage ../pkgs/update-intrustd-appliance { inherit intrustdDir; };
         })
      ];

      nix.binaryCachePublicKeys = [ "cache.intrustd.com-1:7JJMfk9Vl5tetCyL8TnGSmo6IMvJypOlLv4Y7huDvDQ=" ];
      nix.binaryCaches = lib.mkOverride 10 [ "https://hydra.intrustd.com/cache" ];

      environment.systemPackages = [ pkgs.update-intrustd-appliance ];

      # We serialize a representation of the currently booted kernel and
      # initrd into this file. We can use it to determine if we need to
      # restart this device after an update by comparing
      # /run/booted-system/etc/intrustd-appliance-boot-info and
      # /run/current-system/etc/intrustd-appliance-boot-info.
      environment.etc."intrustd-appliance-boot-info".text = ''
      BOOTED_KERNEL=${config.boot.kernelPackages.kernel}
      BOOTED_INITRD=${config.system.build.initialRamdisk}
      '';

      environment.etc."intrustd/caches".text = ''
         https://hydra.intrustd.com/cache cache.intrustd.com-1:7JJMfk9Vl5tetCyL8TnGSmo6IMvJypOlLv4Y7huDvDQ=
      '';

      services.fcron.enable = true;
      services.fcron.systab = ''
      %hourly,mailto(intrustd),random(true),erroronlymail(true) * ${nixGcScript}
      '';

      runit.services.intrustd-updates = {
        requires = [ "network" "nix-daemon" "mounts" ];
        path = [ pkgs.socat pkgs.coreutils ];

        script = ''
          set -e

          mkdir -p ${intrustdDir}
          rm -f ${intrustdDir}/admin.sock ${intrustdDir}/system-socket
          socat UNIX-LISTEN:${intrustdDir}/system-socket,fork,user=intrustd,group=intrustd exec:${pkgs.update-intrustd-appliance}/share/intrustd/intrustd-update-server,stderr
        '';
      };
    }

    (lib.mkIf (config.intrustd.updates.hydraJobUrl != null) {
      environment.etc."intrustd-update-url".text = "${config.intrustd.updates.hydraJobUrl}";
    })
  ];
}
