{ pkgs, lib, config, ... }:

with lib;

let stateDir = "/var/kite";

    installAppScript = name: pkg: ''
      echo "Installing ${name}..."

      cp "${pkg}" /run/manifest.json
      ${lib.getBin pkgs.openssl_1_1}/bin/openssl dgst -sha256 -sign ${stateDir}/key.pem /run/manifest.json | ${lib.getBin pkgs.openssl_1_1}/bin/openssl base64 -out /run/manifest.json.sign

      ${config.services.kite.package.appliancectl}/bin/appliancectl register-app -f file:///run/manifest.json

      rm /run/manifest.json
      rm /run/manifest.json.sign
    '';

    flockSubmoduleOpts = {
      options = {
        url = mkOption {
          type = types.string;
          description = "Flock url in standard kite format";
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
      (concatStringsSep "\n" (flip mapAttrsToList config.services.kite.flocks (name: flock:
         "${flock.url} ${flock.fingerprint}"
      )));

    makeTrustedKey = name: { source, publicKey, ... }:
      pkgs.writeText "trusted-key-${name}"
        (if source != null
         then builtins.readFile source
         else publicKey);

    trustedKeysDir = pkgs.linkFarm "trusted-keys"
      (flip mapAttrsToList config.services.kite.trustedKeys
        (keyName: cfg: { name = "${keyName}.pem";
                         path = makeTrustedKey keyName cfg; }));

in {
  options = {
    services.kite = {
      enable = mkOption {
        type = types.bool;
        description = ''
          Whether to enable the kite service
        '';
        default = true;
      };

      package = mkOption {
        type = types.package;
        description = ''
          Which package to use as the default kite package
        '';
      };

      flocks = mkOption {
        type = types.attrsOf (types.submodule flockSubmoduleOpts);
        default = { };
        description = ''
          Flocks to configure automatically on this kite
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
          kite-static = self.callPackage ../pkgs/kite-static { };
          kite = self.callPackage ../pkgs/kite { curl = kite-curl; };
          kite-curl = super.curl.override {
            c-aresSupport = true; sslSupport = true; idnSupport = true;
            scpSupport = true; gssSupport = true;
            brotliSupport = true; openssl = super.openssl_1_1;
          };
        })
      ];

      services.kite.package = lib.mkDefault pkgs.kite; #(pkgs.kite.override { enableVerboseWebrtc = true; });
    }

    (mkIf config.services.kite.enable {
       users.users = singleton {
         name = "kite";
         uid = config.ids.uids.kite;
         description = "`kite` applianced separation user";
         home = "/var/empty";
       };

       users.groups = singleton {
         name = "kite";
         gid = config.ids.gids.kite;
       };

       runit.services = {
         kite = {
           logging = { enable = true; redirectStderr = true; };
           requires = [ "network" "nix-daemon" ];
	   path = [ config.nix.package.out ];
           environment.KITEPATH = "${config.services.kite.package.applianced}/bin";
           user = "kite";
           groups = [ "kite" ];
           script = ''
             mkdir -p ${stateDir}

	     cd ${stateDir}
             exec ${config.services.kite.package.applianced}/bin/applianced \
               --ebroute ${pkgs.ebtables}/bin/ebtables \
               --iproute ${pkgs.iproute}/bin/ip \
               -c ${stateDir}
           '';
         };

         kite-install = {
           logging = { enable = true; redirectStderr = true; };
           requires = [ "kite" "nix-daemon" ];
           environment.KITE_APPLIANCE_DIR = "${stateDir}";
           oneshot = true;
           script = ''
             ${pkgs.coreutils}/bin/sleep 4
             echo "Installing apps"
             ${concatStringsSep "\n" (mapAttrsToList installAppScript config.services.kite.applications)}
           '';
         };
       };

       system.activationScripts.kite = {
         text = ''
           mkdir -p ${stateDir}
           if [ ! -f ${stateDir}/key.pem ]; then
             echo "Generating Kite Private Key"
             ${lib.getBin pkgs.openssl_1_1}/bin/openssl ecparam -out "${stateDir}/key.ecparam.pem" -name prime256v1
             ${lib.getBin pkgs.openssl_1_1}/bin/openssl genpkey -paramfile "${stateDir}/key.ecparam.pem" -out "${stateDir}/key.pem"
           fi

           chown kite:kite ${stateDir}/key.pem
           cp ${flocksFile} ${stateDir}/flocks
           chown kite:kite ${stateDir}/flocks

           mkdir -p ${stateDir}/trusted_keys
           for i in ${trustedKeysDir}/*; do
             ln -sf $i ${stateDir}/trusted_keys/$(basename $i)
           done
           ${lib.getBin pkgs.openssl_1_1}/bin/openssl ec -in ${stateDir}/key.pem -pubout -out ${stateDir}/trusted_keys/built_here_key.pem
           chown -R kite:kite ${stateDir}/trusted_keys

           chown kite:kite ${stateDir}

           rm -f ${stateDir}/admin.sock
           ln -s "${stateDir}/personas/0000000000000000000000000000000000000000000000000000000000000000/data/admin.flywithkite.com/admin.sock" "${stateDir}/admin.sock"
         '';
         deps = [];
       };
     })
  ];
}
