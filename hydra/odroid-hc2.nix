let app = import ../kite-appliance.nix { platform = "odroid-hc2"; nixpkgs-path = <nixpkgs>; };
in { baseSystem = { ... }: app.baseSystem; }
