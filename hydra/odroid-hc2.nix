let app = import ../kite-appliance.nix {
            platform = "odroid-hc2";
            nixpkgs-path = <nixpkgs>;
            hydraJobUrl = "https://hydra.flywithkite.com/job/kitesystems/odroid-hc2/baseSystem";
          };
in { baseSystem = { ... }: app.baseSystem; }
