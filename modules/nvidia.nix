{
  pkgs,
  config,
  lib,
  nix-config,
  ...
}:  {
  config = lib.mkIf config.modules.hardware.nvidia.enable {
    nixpkgs.config.nvidia.acceptLicense = true;

    hardware = {
      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.beta;

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
        extraPackages = [pkgs.nvidia-vaapi-driver];
      };
    };

    services.udev.packages = [pkgs.linuxPackages.nvidia_x11_beta_open];
    services.xserver.videoDrivers = lib.mkDefault ["nvidia"];

    boot.extraModulePackages = [
      config.boot.kernelPackages.nvidiaPackages.beta
    ];
    boot.kernelParams = ["nvidia-drm.fbdev=1"];
    environment.sessionVariables = {
      GBM_BACKEND = "nvidia-drm";
      NVD_BACKEND = "direct";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      LIBVA_DRIVER_NAME = "nvidia"; # hardware acceleration
      __GL_VRR_ALLOWED = "1";
    };
  };
}
