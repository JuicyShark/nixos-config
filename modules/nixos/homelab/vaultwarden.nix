# Vaultwarden self-hosted password manager + SMTP options.
{
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;
  homelabVaultwarden = config.modules.homelab.vaultwarden.enable;
  inherit (config.modules) ports;
  cfg = config.modules.homelab;
in {
  config = mkIf homelabVaultwarden {
    age.secrets."vaultwarden.env" = {
      file = ../../../secrets/vaultwarden.env.age;
      owner = "vaultwarden";
    };

    services.vaultwarden = {
      enable = true;
      backupDir = "/var/backup/vaultwarden";
      environmentFile = config.age.secrets."vaultwarden.env".path;
      config = {
        DOMAIN = "https://pass.nixlab.au";
        SIGNUPS_ALLOWED = false;
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = ports.vaultwarden;
        WEB_VAULT_ENABLED = true;
        ENABLE_PROMETHEUS_METRICS = true;
        PUSH_ENABLED = true;
        LOG_LEVEL = "info";
        EXTENDED_LOGGING = false;

        WEBSOCKET_ENABLED = true;
        WEBSOCKET_ADDRESS = "127.0.0.1";
        WEBSOCKET_PORT = ports.vaultwardenWs;

        SMTP_HOST = "smtp.gmail.com";
        SMTP_PORT = 465;
        SMTP_SECURITY = "force_tls";
        SMTP_FROM = cfg.smtpEmail;
        SMTP_USERNAME = cfg.smtpEmail;
      };
    };

    services.nginx.virtualHosts."vaultwarden.home.arpa".locations."/" = {
      proxyPass = "http://127.0.0.1:${toString ports.vaultwarden}";
    };
  };
}
