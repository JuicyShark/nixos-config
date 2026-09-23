# Boot Configuration
#
# Manages boot loader, kernel, initrd, and early boot settings.
# Extracted from system.nix for better modularity.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
in {
  config = {
    boot = {
      # Dedicated recovery credential. Its plaintext is encrypted for the
      # operator in secrets/initrd-recovery-password.age.
      initrd.systemd.emergencyAccess = "$6$J1Ma975obw7zdziD$P5MJ7sO.ezItQizSWomRjSR0tihaGtCYdNeGPz/5D4SBtcMPen8uGKqYVo16ilCON8894zBHPpCwxzYJKecsf/";

      tmp.cleanOnBoot = lib.mkDefault (!config.boot.tmp.useTmpfs);

      loader = mkIf (!config.boot.isContainer) {
        systemd-boot = mkIf (pkgs.stdenv.hostPlatform.system != "aarch64-linux") {
          enable = true;
          editor = false;
          configurationLimit = 10;
        };

        timeout = 0;
        efi.canTouchEfiVariables = lib.mkDefault true;
      };

      blacklistedKernelModules = ["floppy"];
      zfs.forceImportRoot = lib.mkDefault false;
    };

    # Systemd boot-related settings
    systemd = {
      settings.Manager.DefaultTimeoutStopSec = "10s";
      services.NetworkManager-wait-online.enable = false;
    };
  };
}
