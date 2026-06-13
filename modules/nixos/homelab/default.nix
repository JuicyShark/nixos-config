{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkDefault mkOption;
  inherit (lib.types) str;
  inherit (config.modules) ports;
in {
  imports = [
    ./media.nix
    ./deluge.nix
    ./vaultwarden.nix
    ./headscale.nix
    ./gatus.nix
    ./filebrowser.nix
    ./syncthing.nix
    ./uptime-kuma.nix
  ];

  options.modules.homelab = {
    smtpEmail = mkOption {
      type = str;
      default = "noreply@localhost";
      description = "Email address for SMTP notifications";
    };

    deluge.enable = mkEnableOption "Deluge torrent client";
    headscale.enable = mkEnableOption "Headscale self-hosted Tailscale coordination server";
    jellyfin = {
      enable = mkEnableOption "Jellyfin media server";
      host = mkOption {
        type = str;
        default = "192.168.1.52";
        description = "Host or address for the Jellyfin backend.";
      };
      adminUsername = mkOption {
        type = str;
        default = "juicy";
        description = "Jellyfin admin username used by Jellyseerr setup.";
      };
    };
    media.enable = mkEnableOption "*arr media acquisition stack (sonarr, radarr, lidarr, prowlarr, jellyseerr)";
    syncthing.enable = mkEnableOption "Syncthing file sync node";
    vaultwarden.enable = mkEnableOption "Vaultwarden self-hosted password manager";
    gatus.enable = mkEnableOption "Gatus declarative uptime monitor";
    uptimeKuma.enable = mkEnableOption "Uptime Kuma service status monitor";
  };

  config = {
    services.nginx = {
      enable = mkDefault true;
      recommendedGzipSettings = mkDefault true;
      recommendedOptimisation = mkDefault true;
      recommendedProxySettings = mkDefault true;

      # Raspberry Pi 5 - HAOS
      virtualHosts."hass.home.arpa".locations."/" = {
        proxyPass = "http://192.168.1.49:${toString ports.homeAssistant}";
        proxyWebsockets = true;
      };
    };
  };
}
