let app = import ../kite-appliance.nix {
            platform = "qemu-x86_64";
            nixpkgs-path = <nixpkgs>;
            hydraJobUrl = "https://hydra.flywithkite.com/job/kitesystems/qemu-x86_64/baseSystem";
          };
in { baseSystem = { ... }: app.baseSystem; }
