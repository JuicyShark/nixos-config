{
  osConfig,
  pkgs,
  lib,
  ...
}: let
  enabled = pkgs.stdenv.isLinux && (osConfig.modules.shairport.enable or false);
  hostName = osConfig.networking.hostName or "shairport";
  confFile = pkgs.writeText "shairport-sync.conf" ''
    general = {
      name = "${hostName}";
      output_backend = "pipewire";
      interpolation = "auto";
      use_precision_clock = "yes";
      udp_port_base = 6001;
      udp_port_range = 10;
    };
    diagnostics = {
      log_verbosity = 1;
    };
  '';
in {
  config = lib.mkIf enabled {
    # User-level shairport-sync instance using shairport's native PipeWire
    # backend, so it follows the user's default sink without requiring root.
    systemd.user.services.shairport-sync = {
      Unit = {
        Description = "Shairport Sync (user) -> PipeWire";
        After = [
          "pipewire.service"
          "wireplumber.service"
        ];
        Wants = [
          "pipewire.service"
          "wireplumber.service"
        ];
      };

      Service = {
        ExecStart = "${pkgs.shairport-sync-airplay2}/bin/shairport-sync -c ${confFile}";
        Restart = "on-failure";
        RestartSec = 2;
      };

      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}
