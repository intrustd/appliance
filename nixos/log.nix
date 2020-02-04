{ config, lib, pkgs, ... }:

{
  runit.services.syslog = {
    path = [ pkgs.socklog ];
    user = "nobody";

    script = ''
      exec 2>&1
      socklog unix /dev/log
    '';
  };
}
