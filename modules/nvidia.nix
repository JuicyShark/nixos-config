{
  pkgs,
  config,
  lib,
  nix-config,
  ...
}: let
pkgs-hypr = nix-config.inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  config = lib.mkIf config.modules.hardware.nvidia.enable {
    nixpkgs.config.nvidia.acceptLicense = true;

    hardware = {
      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.beta;

        modesetting.enable = true;
        nvidiaPersistenced = false;
        powerManagement.enable = true;
        powerManagement.finegrained = false;
        open = false;

        nvidiaSettings = false;
      };

      graphics = {
        enable = true;
            package = lib.mkIf config.programs.hyprland.enable (lib.mkForce pkgs-hypr.mesa.drivers);
            enable32Bit = true;
            package32 = lib.mkIf config.programs.hyprland.enable (lib.mkForce pkgs-hypr.pkgsi686Linux.mesa.drivers);
        extraPackages = [ pkgs.nvidia-vaapi-driver ];
      };
    };

    services.udev.packages = [ pkgs.linuxPackages.nvidia_x11 ];
    services.xserver.videoDrivers = lib.mkDefault ["nvidia"];

    boot.extraModulePackages = [

        config.boot.kernelPackages.nvidiaPackages.beta

    ];
    boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
    environment.sessionVariables = {
      GBM_BACKEND = "nvidia-drm";
      NVD_BACKEND = "direct";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      LIBVA_DRIVER_NAME = "nvidia"; # hardware acceleration
      __GL_VRR_ALLOWED = "1";
    };
  };
}
