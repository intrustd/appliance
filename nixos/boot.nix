{config, lib, pkgs, ...}:
{
  imports = [
    ./boards/odroid-hc2.nix
    ./boards/qemu-arm.nix
    ./boards/qemu-x86_64.nix
  ];

  config = {
    boot.boards."${config.kite.platform}".enable = true;
  };

  options = with lib; {
    kite.platform = mkOption {
      type = types.string;
      description = "Platform name";
    };
  };
}
