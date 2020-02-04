{ config, lib, pkgs, ... }:

{
  runit.services.syslog = {
    path = [ pkgs.socklog ];

    # We don't use 'user="nobody"' because socklog will change users
    # automatically and we need root for /dev
    script = ''
      exec 2>&1
      ${pkgs.runit}/bin/chpst -U nobody socklog unix /dev/log
    '';

    logging.redirectStderr = true;
    logging.enable = true;
  };
}
