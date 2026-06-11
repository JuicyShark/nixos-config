{
  config,
  lib,
  ...
}: let
  cfg = config.modules.desktop;
  sunshinePorts = config.modules.ports.sunshine;
in {
  options.modules.desktop.sunshine.enable = lib.mkEnableOption "Sunshine game streaming host";

  config = lib.mkIf cfg.sunshine.enable {
    networking.firewall.allowedTCPPorts = with sunshinePorts; [
      https
      http
      web
      rtsp
    ];
    networking.firewall.allowedUDPPorts = with sunshinePorts; [
      discovery
      video
      control
      audio
      mic
      rtsp
    ];

    assertions = [
      {
        assertion = config.programs.steam.enable;
        message = "Sunshine requires programs.steam.enable == true.";
      }
      {
        assertion = config.programs.hyprland.enable;
        message = "Sunshine requires programs.hyprland.enable == true.";
      }
    ];

    services.sunshine = {
      enable = true;
      autoStart = true;
      openFirewall = false;
      settings.port = config.modules.ports.sunshine.http;
    };

    # Expand this later with Hyprland-specific streaming monitor/workspace
    # wiring once the desired display and GPU behavior is settled.
  };
}
