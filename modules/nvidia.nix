{
  pkgs,
  config,
  lib,
  nix-config,
  ...
}:
{
  config = lib.mkIf config.modules.hardware.nvidia.enable {
    nixpkgs.config.nvidia.acceptLicense = true;

    hardware = {
      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.beta;

        modesetting.enable = true;
        nvidiaPersistenced = true;
        powerManagement.enable = true;
        powerManagement.finegrained = false;
        open = false;

        nvidiaSettings = false;
      };

      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = [ pkgs.nvidia-vaapi-driver ];
      };
    };

    services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];

    boot.extraModulePackages = [
      config.boot.kernelPackages.nvidiaPackages.beta
    ];
    boot.kernelParams = [
      "nvidia-drm.modeset=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
    environment.sessionVariables = {
      WLR_RENDERER = "vulkan"; # REMOVE if issues
      GBM_BACKEND = "nvidia-drm";
      NVD_BACKEND = "direct";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      LIBVA_DRIVER_NAME = "nvidia"; # hardware acceleration
      __GL_VRR_ALLOWED = "1";
      __GL_GSYNC_ALLOWED = "1";
      __GL_MaxFramesAllowed = "1";
    };
  };
}
