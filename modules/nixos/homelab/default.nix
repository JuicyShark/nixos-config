{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption mkEnableOption mkDefault;
  inherit (lib.types) str;
  inherit (config.modules) ports;
in {
  imports = [
    ./media.nix
    ./deluge.nix
    ./vaultwarden.nix
    ./headscale.nix
    ./gatus.nix
    ./paperless.nix
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
    jellyfin.enable = mkEnableOption "Jellyfin media server";
    media.enable = mkEnableOption "*arr media acquisition stack (sonarr, radarr, lidarr, prowlarr, jellyseerr)";
    paperless = {
      enable = mkEnableOption "Paperless-ngx document archive";
      domain = mkOption {
        type = str;
        default = "docs.home.arpa";
        description = "Internal Paperless-ngx virtual host";
      };
      dataDir = mkOption {
        type = str;
        default = "/var/lib/paperless";
        description = "Paperless application state directory";
      };
      mediaDir = mkOption {
        type = str;
        default = "/srv/chonk/paperless/media";
        description = "Paperless document media directory";
      };
      consumptionDir = mkOption {
        type = str;
        default = "/srv/chonk/paperless/consume";
        description = "Paperless document import directory";
      };
      exportDir = mkOption {
        type = str;
        default = "/srv/chonk/paperless/export";
        description = "Paperless document exporter directory";
      };
      ocrLanguage = mkOption {
        type = str;
        default = "eng";
        description = "Tesseract OCR language list for Paperless";
      };
      configureTika = mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Tika and Gotenberg for Office/e-mail document parsing";
      };
    };
    syncthing.enable = mkEnableOption "Syncthing file sync node";
    vaultwarden.enable = mkEnableOption "Vaultwarden self-hosted password manager";
    gatus.enable = mkEnableOption "Gatus declarative uptime monitor";
    uptimeKuma.enable = mkEnableOption "Uptime Kuma service status monitor";
  };

  config = {
    assertions = [
      {
        assertion = !(config.modules.homelab.gatus.enable && config.modules.homelab.uptimeKuma.enable);
        message = "Use either Gatus or Uptime Kuma for status monitoring. This repo's preferred declarative path is Gatus.";
      }
    ];

    services.nginx = {
      enable = mkDefault true;
      recommendedGzipSettings = mkDefault true;
      recommendedOptimisation = mkDefault true;
      recommendedProxySettings = mkDefault true;

      virtualHosts."hass.home.arpa".locations."/" = {
        proxyPass = "http://192.168.1.49:${toString ports.homeAssistant}";
        proxyWebsockets = true;
      };
    };
  };
}
