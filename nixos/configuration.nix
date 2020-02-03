{lib, pkgs, config, ...}:

{
  imports = [ ./networking.nix ./ssh.nix ./intrustd.nix ./apps.nix ./updates.nix ./avahi.nix ];

  nixpkgs.overlays = [
    (self: super: {
      odroid-xu4-firmware = self.callPackage ../pkgs/boards/xu4-firmware {};
      ubootOdroidXU4 = self.callPackage ../pkgs/boards/uboot-xu4 {};
     })
  ];

  nix.nrBuildUsers = 8;

  # TODO enable ZRAM (ram compression)

  ## Hardening

  # Do not allow services running as other users to view process information
  security.hideProcessInformation = true;

  # All our kernels are built with important features (like SCTP) built-in, or loaded at boot
  security.lockKernelModules = true;

  # No need for sudo here. All necessary commands will already be marked as setsuid?
  security.sudo.enable = false;

  # Pam USB?
  # Auditing?

  # TODO more hardening

  # TODO checkpoint/restore

  # TODO services.klogd.enable = true

  # TODO  services.atd.enable = true;
  # TODO services.cron.enable = true;

  environment.etc."os-release".text = lib.mkOverride 10 ''
    NAME=IntrustdOS
    ID=intrustd
    VERSION="${config.system.nixos.version} (${config.system.nixos.codeName})"
    VERSION_CODENAME=${lib.toLower config.system.nixos.codeName}
    VERSION_ID="${config.system.nixos.version}"
    PRETTY_NAME="IntrustdOS ${config.system.nixos.version} (${config.system.nixos.codeName})"
    HOME_URL="https://intrustd.com/"
    SUPPORT_URL="https://intrustd.com/support"
    BUG_REPORT_URL="https://github.com/intrustd/appliance/issues"
  '';
}
