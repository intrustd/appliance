{config, pkgs, ...}:

{
  networking.useDHCP = false; # Don't auto-configure network interfaces

  networking.interfaces.eth0 = {
    useDHCP = true;
  };
  networking.dhcpcd.allowInterfaces = null;

  networking.hostName = "intrustd";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 ];
    extraCommands = "iptables -I INPUT 1 -i intrustd-inet -j ACCEPT";
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "intrustd-inet" ];
    internalIPs = [ "10.0.0.0/8" ];
    externalInterface = "eth0";
  };

  # enable unbound
  services.nscd.enable = false; # Using unbound instead
  services.unbound = {
    enable = true;
    remoteControl.enable = true;

    interfaces = [ "127.0.0.1" "::1" "10.254.254.254" ];
    allowedAccess = [ "127.0.0.0/24" "10.0.0.0/8" ];

    forwardAddresses = [
      # Quad 9
      "2620:fe::fe@853#dns.quad9.net"
      "9.9.9.9@853#dns.quad9.net"
      "2620:fe::9@853#dns.quad9.net"
      "149.112.112.112@853#dns.quad9.net"

      # CloudFlare
      "2606:4700:4700::1111@853#cloudflare-dns.com"
      "1.1.1.1@853#cloudflare-dns.com"
      "2606:4700:4700::1001@853#cloudflare-dns.com"
      "1.0.0.1@853#cloudflare-dns.com"
    ];
    forwardTlsUpstream = true;

    rootHints = ./root.hints;
  };

  networking.nameservers = [ "127.0.0.1" ];
  networking.dnsExtensionMechanism = false;

  # enable time synchronization
  services.openntpd.enable = true;
  services.openntpd.extraOptions = "-s"; # Set time immediately on startup

  # enable avahi (mdns / bonjour)
  services.avahi.enable = true;
  services.avahi.ipv6 = true;
  services.avahi.publish.enable = true;
  services.avahi.publish.userServices = true;

  services.udev.extraRules = ''
    KERNEL=="tun", GROUP="intrustd", MODE="0660", OPTIONS+="static_node=net/tun"
  '';

  # Intrsutd applianced

  services.intrustd = {
    enable = true;

    flocks."intrustd.com" = {
      url = "intrustd+flock://flock.intrustd.com:6854";
      fingerprint = "3085a1e28bcb83be1571798786496aa699ec0f59d46b9d5069598db0f595b310";
    };

    flocks."stun".url = "stun://stun.stunprotocol.org:3478";

    trustedKeys.intrustd.source = ./trusted-keys/intrustd.pem;
  };

  services.lighttpd = {
    enable = true;

    document-root = pkgs.intrustd-static;
    enableModules = [ "mod_scgi" "mod_setenv" "mod_rewrite" "mod_accesslog" ];

    extraConfig = ''
      url.rewrite-once = ( "^/login(/)?$" => "/login.html" )

      server.stream-request-body = 2

      setenv.add-request-header = (
        "X-Intrustd-Admin-Source" => "local-network"
      )

      $HTTP["url"] =~ "^/admin/" {
        scgi.protocol = "uwsgi"
        scgi.server = (
          "/admin" => (( "socket" => "${config.services.intrustd.stateDir}/admin.sock", "check-local" => "disable" ))
        )
      }
    '';
  };

  users.users.lighttpd.extraGroups = [ "intrustd" ];
}
