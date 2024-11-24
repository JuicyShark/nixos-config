{
  pkgs,
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.modules.hardware.nvidia.enable {
    nixpkgs.config.nvidia.acceptLicense = true;

    environment.systemPackages = with pkgs; [
      libva
    ];

    hardware = {
      nvidia = {
        # Explicit Sync is here
        package =
          if config.modules.hardware.nvidia.legacy
          then config.boot.kernelPackages.nvidiaPackages.legacy_470
          else config.boot.kernelPackages.nvidiaPackages.beta;
        modesetting.enable = true;
        nvidiaPersistenced = false;
        powerManagement.enable = true;
        powerManagement.finegrained = false;
        open = true;
        nvidiaSettings = false;
      };

      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = [ pkgs.vaapiVdpau ];
      };
    };


    services.xserver.videoDrivers = lib.mkDefault ["nvidia"];

    boot.extraModulePackages = [
      (
        if config.modules.hardware.nvidia.legacy
        then config.boot.kernelPackages.nvidia_x11_legacy470
        else config.boot.kernelPackages.nvidiaPackages.beta
      )
    ];
    boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
    environment.sessionVariables = {
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      LIBVA_DRIVER_NAME = "nvidia"; # hardware acceleration
      __GL_VRR_ALLOWED = "1";
    };
  };
}
