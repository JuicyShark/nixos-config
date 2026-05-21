# iPhone / iPad USB integration.
#
# usbmuxd is the userspace daemon that proxies the iOS device's USB
# multiplexing socket; libimobiledevice provides the CLI/tooling
# (idevicepair, ideviceinfo, idevicebackup2, …) and ifuse mounts the
# device's media partition via FUSE so Yazi/imv/etc. see photos and
# documents directly.
#
# Wi-Fi sync also goes through usbmuxd once the device is paired over USB,
# so iPhones/iPads on the same network show up without a cable after the
# initial pairing.
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

    # gvfs is already enabled on desktops; the AFC backend ships with it
    # and lets file managers open afc:// URIs directly. We add the
    # libimobiledevice udev rules explicitly so the user gets access to
    # /dev/bus/usb/* without the desktop module having to know.
    services.udev.packages = [pkgs.libimobiledevice];

    environment.systemPackages = with pkgs; [
      libimobiledevice
      ifuse
    ];
  };
}
