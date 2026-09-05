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

    sessioncontrol = {
      allow_session_interruption = "yes";
      session_timeout = 120;
    };
  '';
in {
  config = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && (osConfig.modules.shairport.enable or false)) {
    systemd.user.services.shairport-sync = {
      Unit = {
        Description = "Shairport Sync AirPlay receiver";
        After = ["pipewire.service" "wireplumber.service" "network-online.target"];
        Wants = ["network-online.target"];
      };
      Service = {
        ExecStart = "${lib.getExe pkgs.shairport-sync} -c ${confFile}";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
