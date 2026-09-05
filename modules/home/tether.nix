{
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfg = osConfig.modules.tether;
in {
  config = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && cfg.enable) {
    home.packages = [pkgs.tether];

    systemd.user.services.tether = {
      Unit = {
        Description = "Tether iPhone integration daemon";
        Documentation = "https://github.com/zackb/tether";
        After = ["graphical-session.target" "network-online.target"];
        Wants = ["network-online.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = lib.getExe' pkgs.tether "tetherd";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
