# Vaultwarden self-hosted password manager + SMTP options.
{
  ports,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.services.vaultwarden.enable {
    age.secrets."vaultwarden.env" = {
      file = ../../../secrets/vaultwarden.env.age;
      owner = "vaultwarden";
    };

    services.vaultwarden = {
      environmentFile = config.age.secrets."vaultwarden.env".path;
      config = {
        DOMAIN = "https://pass.nixlab.au";
        SIGNUPS_ALLOWED = false;
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = ports.vaultwarden;
        WEB_VAULT_ENABLED = true;
        ENABLE_PROMETHEUS_METRICS = true;
        PUSH_ENABLED = true;
        LOG_LEVEL = "warn";
        EXTENDED_LOGGING = false;

        SMTP_HOST = "smtp.gmail.com";
        SMTP_PORT = 465;
        SMTP_SECURITY = "force_tls";
      };
    };

    services.nginx.virtualHosts."vaultwarden.home.arpa".locations."/" = {
      proxyPass = "http://127.0.0.1:${toString ports.vaultwarden}";
      proxyWebsockets = true;
    };
  };
}
