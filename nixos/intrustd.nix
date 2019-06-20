{ pkgs, lib, config, ... }:

with lib;

let stateDir = config.services.intrustd.stateDir;

    intrustdInitScript = ''
      mkdir -p ${stateDir}
      if [ ! -f ${stateDir}/key.pem ]; then
        echo "Generating Intrustd Private Key"
        ${lib.getBin pkgs.openssl_1_1}/bin/openssl ecparam -out "${stateDir}/key.ecparam.pem" -name prime256v1
        ${lib.getBin pkgs.openssl_1_1}/bin/openssl genpkey -paramfile "${stateDir}/key.ecparam.pem" -out "${stateDir}/key.pem"
      fi

      chown intrustd:intrustd ${stateDir}/key.pem
      cp ${flocksFile} ${stateDir}/flocks
      chown intrustd:intrustd ${stateDir}/flocks

      mkdir -p ${stateDir}/trusted_keys
      for i in ${trustedKeysDir}/*; do
        ln -sf $i ${stateDir}/trusted_keys/$(basename $i)
      done
      ${lib.getBin pkgs.openssl_1_1}/bin/openssl ec -in ${stateDir}/key.pem -pubout -out ${stateDir}/trusted_keys/built_here_key.pem
      chown -R intrustd:intrustd ${stateDir}/trusted_keys

      chown intrustd:intrustd ${stateDir}

      touch ${stateDir}/intrustd-system-update.lock
      chown intrustd:intrustd ${stateDir}/intrustd-system-update.lock

      rm -f ${stateDir}/admin.sock
      ln -s "${stateDir}/personas/0000000000000000000000000000000000000000000000000000000000000000/data/admin.intrustd.com/admin.sock" "${stateDir}/admin.sock"
    '';

    installAppScript = name: pkg: ''
      echo "Installing ${name}..."
      installApp "${name}" "${pkg}"
    '';

    installAppFn = ''
      doInstallApp () {
        local line
        local app
        while read -r line || [ -n "$line" ]; do
          app=$(echo "$line" | ${lib.getBin pkgs.gawk}/bin/gawk -F ' ' '{ print $1 }')
          if [ x"$app" == x"$1" ]; then
            echo "$1 $2"
          else
            echo "$line"
          fi
        done
      }

      installApp () {
        local mf_digest=$(cat "$2" | ${lib.getBin pkgs.openssl_1_1}/bin/openssl dgst -sha256 | ${lib.getBin pkgs.gawk}/bin/gawk '{print $2}')

        mkdir -p "${stateDir}/manifests"
        chown intrustd:intrustd "${stateDir}/manifests"
        cp "$2" "${stateDir}/manifests/$mf_digest"
        ${lib.getBin pkgs.openssl_1_1}/bin/openssl dgst -sha256 -sign ${stateDir}/key.pem "$2" | ${lib.getBin pkgs.openssl_1_1}/bin/openssl base64 -out "${stateDir}/manifests/$mf_digest.sign"

        if [ -e "${stateDir}/apps" ]; then
          cat "${stateDir}/apps" | doInstallApp "$1" "$mf_digest" > "${stateDir}/.apps.tmp"
        else
          echo "$1 $mf_digest" > "${stateDir}/.apps.tmp"
        fi
        chown intrustd:intrustd "${stateDir}/manifests"

        mv "${stateDir}/.apps.tmp" "${stateDir}/apps"
      }
    '';


    flockSubmoduleOpts = {
      options = {
        url = mkOption {
          type = types.string;
          description = "Flock url in standard intrustd format";
        };

        fingerprint = mkOption {
          type = types.string;
          description = "Flock certificate fingerprint";
        };
      };

      config = {
        fingerprint = mkDefault "0000000000000000000000000000000000000000000000000000000000000000";
      };
    };

    trustedKeysSubmoduleOpts = {
      options = {
        source = mkOption {
          type = types.nullOr types.path;
          description = "Path to the trusted key public key PEM file. This or publicKey must be set";
          default = null;
        };

        publicKey = mkOption {
          type = types.nullOr types.string;
          description = "Text of PEM public key";
          default = null;
        };
      };
    };

    flocksFile = pkgs.writeText "flocks"
      (concatStringsSep "\n" (flip mapAttrsToList config.services.intrustd.flocks (name: flock:
         "${flock.url} ${flock.fingerprint}"
      )));

    makeTrustedKey = name: { source, publicKey, ... }:
      pkgs.writeText "trusted-key-${name}"
        (if source != null
         then builtins.readFile source
         else publicKey);

    trustedKeysDir = pkgs.linkFarm "trusted-keys"
      (flip mapAttrsToList config.services.intrustd.trustedKeys
        (keyName: cfg: { name = "${keyName}.pem";
                         path = makeTrustedKey keyName cfg; }));

in {
  options = {
    services.intrustd = {
      enable = mkOption {
        type = types.bool;
        description = ''
          Whether to enable the intrustd appliance service
        '';
        default = true;
      };

      stateDir = mkOption {
        type = types.string;
        description = ''
          Path to intrustd appliance state dir
        '';
        default = "/var/intrustd";
      };

      package = mkOption {
        type = types.package;
        description = ''
          Which package to use as the default intrustd package
        '';
      };

      flocks = mkOption {
        type = types.attrsOf (types.submodule flockSubmoduleOpts);
        default = { };
        description = ''
          Flocks to configure automatically on this intrustd appliance
        '';
      };

      trustedKeys = mkOption {
        type = types.attrsOf (types.submodule trustedKeysSubmoduleOpts);
        default = { };
        description = ''
          Signing keys we should trust for administrative applications
        '';
      };

      # Applications that must be installed. If not present, these will be forcefully installed
      applications = mkOption {
        type = types.attrsOf types.package;
        default = { };
        description = ''
          Links to packages that ought to be distributed with the device.

          These may be updated.
        '';
      };
    };
  };

  config = mkMerge [
    {
      nixpkgs.overlays = [
        (self: super: rec {
          lksctp-tools = self.callPackage ../pkgs/lksctp-tools {};
          nix-fetch = self.callPackage ../pkgs/nix-fetch {};
          intrustd-static = self.callPackage ../pkgs/intrustd-static { };
          intrustd = self.callPackage ../pkgs/intrustd { curl = intrustd-curl; };
          intrustd-curl = super.curl.override {
            c-aresSupport = true; sslSupport = true; idnSupport = true;
            scpSupport = true; gssSupport = true;
            brotliSupport = true; openssl = super.openssl_1_1;
          };
        })
      ];

      services.intrustd.package = lib.mkDefault pkgs.intrustd;
    }

    (mkIf config.services.intrustd.enable {
       users.users = [
         {
           name = "intrustd";
           uid = config.ids.uids.intrustd;
           description = "`intrustd` applianced separation user";
           home = "/var/empty";
         }

         {
           name = "intrustd-user";
           uid = config.ids.uids.intrustd-user;
           description = "Unprivileged intrustd user";
           home = "/var/empty";
         }
       ];

       users.groups = [
         {
           name = "intrustd";
           gid = config.ids.gids.intrustd;
         }

         {
           name = "intrustd-user";
           gid = config.ids.gids.intrustd-user;
         }
       ];

       runit.services = {
         intrustd = {
           logging = { enable = true; redirectStderr = true; };
           requires = [ "network" "nix-daemon" "mounts" ];
	   path = [ config.nix.package.out pkgs.nix-fetch ];

           waitTime = 3600; # Wait up to an hour for everything to start. This should be way more than enough

           environment.INTRUSTDPATH = "${config.services.intrustd.package.applianced}/bin";
           environment.HOME = stateDir;

           script = ''
             set -e

             ${intrustdInitScript}
	     cd ${stateDir}

             ${installAppFn}

             # Install static apps
             ${concatStringsSep "\n" (mapAttrsToList installAppScript config.services.intrustd.applications)}

             exec ${config.services.intrustd.package.applianced}/bin/applianced \
               --ebroute ${pkgs.ebtables}/bin/ebtables \
               --iproute ${pkgs.iproute}/bin/ip \
               -c ${stateDir} \
               -H ${pkgs.stdenv.hostPlatform.config} \
               --user intrustd --group intrustd \
               --app-user intrustd-user --app-group intrustd-user \
               --resolv-conf ${pkgs.writeText "resolv.conf" "nameserver 10.254.254.254\n"}
           '';
         };
       };

       nix.trustedUsers = [ "intrustd" ];
     })
  ];
}
