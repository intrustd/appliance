let app = import ../appliance.nix {
            platform = "odroid-hc2";
            nixpkgs-path = <nixpkgs>;
            hydraJobUrl = "https://hydra.intrustd.com/job/intrustd/odroid-hc2/baseSystem";
          };
in { inherit (app) baseSystem sdCard; }
