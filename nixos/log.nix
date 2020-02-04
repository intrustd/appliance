{ config, lib, pkgs, ... }:

{
  runit.services.syslog = {
    path = [ pkgs.runit ];
    user = "nobody";

    script = ''
      exec 2>&1
      ${pkgs.runit}/bin/socklog unix /dev/log
    '';
  };
}
