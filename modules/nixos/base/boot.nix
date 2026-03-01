# Boot Configuration
#
# Manages boot loader, kernel, initrd, and early boot settings.
# Extracted from system.nix for better modularity.

{
  nix-config,
  system,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.system;
  inherit (nix-config.lib.${system}.roles) mkHasRole;
  hasRole = mkHasRole config;
in
{
  config = {
    boot = {
      initrd.systemd.emergencyAccess = true;

      tmp = if hasRole "ram-high" then { useTmpfs = true; } else { cleanOnBoot = true; };

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
        efi.canTouchEfiVariables = builtins.pathExists "/sys/firmware/efi";
      };

      kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_stable;
      blacklistedKernelModules = [ "floppy" ];
    };

    # Systemd boot-related settings
    systemd = {
      settings.Manager.DefaultTimeoutStopSec = "10s";
      services.NetworkManager-wait-online.enable = false;
    };

    # ZRam swap configuration
    zramSwap = {
      enable = false;
      memoryPercent = 25;
    };
  };
}
