{
  pkgs,
  config,
  lib,
  ...
}:

let
  inherit (builtins) toJSON;

  inherit (lib)
    mkEnableOption
    mkIf
    ;

  inherit (cfg)
    bluetooth
    nvidia
    ;


  cfg = config.modules.hardware;
in
{
  options.modules.hardware = {
    keyboardBinds = mkEnableOption "caps lock as ctrl when held and esc when tapped";
    mouseSettings = mkEnableOption "piper for gaming mice";
    bluetooth = mkEnableOption "bluetooth support";
    nvidia = {
      enable = mkEnableOption "Nvidia drivers";
      legacy = mkEnableOption "Legacy drivers";
    };
  };

  config = {
    hardware.bluetooth.enable = mkIf bluetooth true;
 #   hardware.nvidia-container-toolkit.enable = nvidia.enable;

    services = {
      blueman.enable = mkIf bluetooth true;
    };

    environment.systemPackages = [
      (
        if nvidia.enable
        then (pkgs.zenith-nvidia)
        else (pkgs.zenith)
      )
    ];
  };
}
