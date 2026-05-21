{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf optionals;

  cfg = config.modules.recomp;
in {
  options.modules.recomp = {
    enable = mkEnableOption "N64 recompilation ports and tools";

    romPorts.enable = mkEnableOption "ROM-backed recompilation ports";
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      [pkgs.n64recomp]
      ++ optionals cfg.romPorts.enable (with pkgs; [
        zelda64recomp
        banjorecomp
        starfox64recomp
        mariokart64recomp
      ]);
  };
}
