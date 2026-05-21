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
  cfg = config.modules.system;
in {
  config = {
    boot = {
      initrd.systemd.emergencyAccess = true;

      tmp =
        if cfg.highMemory.enable
        then {useTmpfs = true;}
        else {cleanOnBoot = true;};

      binfmt.emulatedSystems = mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        "aarch64-linux"
      ];

      loader = mkIf (!config.boot.isContainer) {
        systemd-boot = mkIf (pkgs.stdenv.hostPlatform.system != "aarch64-linux") {
          enable = true;
          editor = false;
          configurationLimit = 10;
        };

        timeout = 0;
        efi.canTouchEfiVariables = lib.mkDefault true;
      };

      kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_stable;
      blacklistedKernelModules = ["floppy"];
      zfs.forceImportRoot = lib.mkDefault false;
    };

    # Systemd boot-related settings
    systemd = {
      settings.Manager.DefaultTimeoutStopSec = "10s";
      services.NetworkManager-wait-online.enable = false;
    };

    # ZRam swap: enabled on high-memory machines to absorb transient pressure
    # without hitting the swap partition (especially under gaming + compile loads).
    zramSwap = {
      inherit (cfg.highMemory) enable;
      memoryPercent = 25;
    };
  };
}
