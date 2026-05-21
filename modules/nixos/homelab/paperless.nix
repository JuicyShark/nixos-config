{
  config,
  lib,
  ...
}: let
  cfg = config.modules.homelab.paperless;
  inherit (config.modules) ports;
in {
  config = lib.mkIf cfg.enable {
    services = {
      paperless = {
        enable = true;
        address = "127.0.0.1";
        port = ports.paperless;
        inherit (cfg) dataDir mediaDir consumptionDir configureTika domain;
        consumptionDirIsPublic = false;
        database.createLocally = true;
        configureNginx = true;
        exporter = {
          enable = true;
          directory = cfg.exportDir;
          onCalendar = "01:30";
        };
        settings = {
          PAPERLESS_URL = lib.mkForce "http://${cfg.domain}";
          PAPERLESS_ALLOWED_HOSTS = "${cfg.domain},localhost,127.0.0.1";
          PAPERLESS_CSRF_TRUSTED_ORIGINS = "http://${cfg.domain}";
          PAPERLESS_OCR_LANGUAGE = cfg.ocrLanguage;
          PAPERLESS_OCR_SKIP_ARCHIVE_FILE = "with_text";
        };
      };

      nginx.virtualHosts.${cfg.domain} = {
        forceSSL = lib.mkForce false;
        enableACME = lib.mkForce false;
        extraConfig = ''
          client_max_body_size 512m;
          allow ${config.modules.network.subnets.lan};
          allow ${config.modules.network.subnets.tailscale};
          deny all;
        '';
      };
    };

    systemd.services = {
      paperless-scheduler.unitConfig.RequiresMountsFor = ["/srv/chonk"];
      paperless-task-queue.unitConfig.RequiresMountsFor = ["/srv/chonk"];
      paperless-consumer.unitConfig.RequiresMountsFor = ["/srv/chonk"];
      paperless-web.unitConfig.RequiresMountsFor = ["/srv/chonk"];
      paperless-exporter.unitConfig.RequiresMountsFor = ["/srv/chonk"];
    };
  };
}
