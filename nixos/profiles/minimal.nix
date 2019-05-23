{ lib, pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.testdisk
    pkgs.parted

    pkgs.sdparm
    pkgs.hdparm
    pkgs.pciutils
    pkgs.usbutils
    pkgs.smartmontools

    pkgs.unzip
    pkgs.zip

    pkgs.psmisc # pstree

#    pkgs.python#Remove
  ];

  boot.supportedFilesystems = [ "btrfs" "vfat"  ];

  networking.hostId = "8425e349";

  environment.noXlibs = true;
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  documentation.enable = false;
  sound.enable = false;

  nixpkgs.overlays = [ (self: (super: {
    mesa_noglu = (super.mesa_noglu.override {
      eglPlatforms = [ "drm" ];
      driDrivers = [ "swrast" ];
      galliumDrivers = [ "swrast" ];
      vulkanDrivers = [];
      enableLLVM = false;
      enableValgrindHints = false;
    });

    libvpx = super.libvpx.override { examplesSupport = false; };
    libva = super.libva.override { minimal = true; };

    ffmpeg = super.ffmpeg.override { sdlSupport = false; glSupport = false;
                                     libpulseaudio = null; samba = null;
                                     openal = null; libjack2 = null;
                                     libmodplug = null; };

    #cairo = super.cairo.override { glSupport = false; };

    #libdevil = super.libdevil.override { libGL = null; libX11 = null; };

    gnupg22 = super.gnupg22.override { openldap = null; guiSupport = false; pinentry = null; };
    gnupg = self.gnupg22;

    libselinux = super.libselinux.override { fts = null; };

    nix = super.nix.override { withAWS = false; }; # AWS is needed to write. We don't need that

    lighttpd = super.lighttpd.override { enableWebDAV = false; };

    libwebp = super.libwebp.override { gifSupport = false; giflib = null; };
#    systemd = super.systemd.override {
#      withSelinux = false;
#      enableHibernate = false;
#      enableRFKill = false;
#      enableKmod = false;
#      enableUtmp = false;
#    };
  })) ];

  systemd.enable = false;

  runit.enable = true;

  services.udisks2.enable = false;
  security.rngd.enable = true;
  security.polkit.enable = false;
#  environment.minimal = true;
  programs.command-not-found.enable = false;

  nix.checkConfig = false; # Can't do this when cross-compiling

  # Allow the user to log in as root without a password.
  users.users.root.password = "odroid";
}
