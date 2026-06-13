{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.ios;
in {
  options.modules.ios = {
    enable = lib.mkEnableOption "iPhone/iPad USB pairing, mounting, and tooling";
  };

  config = lib.mkIf cfg.enable {
    services.usbmuxd.enable = true;
    services.udev.packages = [pkgs.libimobiledevice];

    environment.systemPackages = with pkgs; [
      libimobiledevice
      ifuse
    ];
  };
}
