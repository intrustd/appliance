{config, lib, pkgs, ...}:
{
  imports = [
    ./boards/odroid-hc2.nix
    ./boards/qemu-arm.nix
    ./boards/qemu-x86_64.nix
  ];

  config = {
    boot.boards."${config.intrustd.platform}".enable = true;
  };

  options = with lib; {
    intrustd.medium = mkOption {
      type = types.string;
      description = "Medium (vbox, sd, etc.)";
    };

    intrustd.platform = mkOption {
      type = types.string;
      description = "Platform name";
    };
  };
}
