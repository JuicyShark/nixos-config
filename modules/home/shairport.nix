{
  osConfig,
  pkgs,
  lib,
  ...
}: let
  name = osConfig.modules.shairport.name or (osConfig.networking.hostName or "shairport");
  interface = osConfig.modules.shairport.interface or null;
  confFile = pkgs.writeText "shairport-sync.conf" ''
    general = {
      name = ${builtins.toJSON name};
      output_backend = "pipewire";
      mdns_backend = "avahi";
      ${lib.optionalString (interface != null) "interface = ${builtins.toJSON interface};"}
      port = 5000;
      interpolation = "auto";
      udp_port_base = 6001;
      udp_port_range = 10;
    };
    diagnostics = {
      log_verbosity = 1;
    };
  '';
in {
  config = lib.mkIf (pkgs.stdenv.isLinux && (osConfig.modules.shairport.enable or false)) {
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
        ExecStart = "${pkgs.shairport-sync}/bin/shairport-sync -c ${confFile}";
        Restart = "on-failure";
        RestartSec = 2;
      };

      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}
