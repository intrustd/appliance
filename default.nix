{ nixpkgs, declInput }:

let pkgs = import <nixpkgs> {};
in {
  jobsets =
    let spec = {
          odroid-hc2 = {
            enabled = 1;
            hidden = false;
            description = "";
            nixexprinput = "src";
            nixexprpath = "hydra/odroid-hc2.nix";
            checkinterval = 300;
            schedulingshares = 100;
            enableemail = true;
            emailoverride = "";
            keepnr = 3;
            inputs = {
              nixpkgs = { type = "git"; value = "git://github.com/kitecomputing/nixpkgs.git aeb470b626d391bcb206a568d68065326a512884"; emailresponsible = true; };
              src = { type = "git"; value = "git://github.com/kitecomputing/kite-system.git"; emailresponsible = true; };
            };
          };
        };
    in pkgs.writeText "spec.json"
         (builtins.toJSON spec);
}
