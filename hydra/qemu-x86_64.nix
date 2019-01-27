let app = import ../appliance.nix {
            platform = "qemu-x86_64";
            nixpkgs-path = <nixpkgs>;
            hydraJobUrl = "https://hydra.intrustd.com/job/intrustd/qemu-x86_64/baseSystem";
          };
in { baseSystem = { ... }: app.baseSystem; }
