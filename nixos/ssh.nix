{
  services.openssh = {
    enable = true;
    forwardX11 = false;

    passwordAuthentication = false; # Only allow authorized keys
  };

  users.users.root.openssh.authorizedKeys.keyFiles = [ /home/tathougies/.ssh/id_rsa.pub ]; # TODO FIXME
}
