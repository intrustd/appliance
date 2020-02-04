{config, pkgs, lib, ...}:

with lib;
{
  options = {
    networking.mdnsServices = mkOption {
      type = with types; attrsOf (either str path);
      default = {};
      description = ''
        Custom avahi *.service files to publish
      '';
    };
  };

  configuration = {
    # enable avahi (mdns / bonjour)
    services.avahi.enable = true;
    services.avahi.ipv6 = true;
    services.avahi.publish.enable = true;
    services.avahi.publish.userServices = true;

   environment.etc =
     lib.mapAttrs' (n: v: nameValuePair
       "avahi/services/${n}.service"
       { ${if lib.types.path.check v then "source" else "text"} = v; })
       config.networking.mdnsServices;
  };
}
