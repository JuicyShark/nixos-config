{
  ports,
  config,
  lib,
  ...
}: let
  enabled = config.modules.monitoring.enable;
  alertEmail = config.modules.monitoring.alertEmail;
in {
  config = lib.mkIf enabled {
    age.secrets.alertmanager-smtp-password = {
      file = ../../../secrets/alertmanager-smtp-password.age;
      mode = "0400";
    };

    services.prometheus = {
      alertmanagers = [
        {
          static_configs = [
            {
              targets = ["127.0.0.1:${toString ports.alertmanager}"];
            }
          ];
        }
      ];

      alertmanager = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = ports.alertmanager;
        # The SMTP password is supplied through a systemd credential at
        # runtime, so build-time amtool cannot open it.
        checkConfig = false;
        webExternalUrl = "http://alertmanager.home.arpa";
        configuration = {
          global = {
            smtp_smarthost = "smtp.gmail.com:465";
            smtp_from = alertEmail;
            smtp_auth_username = alertEmail;
            smtp_auth_password_file = "$CREDENTIALS_DIRECTORY/smtp-password";
            smtp_require_tls = true;
          };
          route = {
            receiver = "email";
            group_by = [
              "alertname"
              "instance"
            ];
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "12h";
          };
          receivers = [
            {
              name = "email";
              email_configs = [
                {
                  to = alertEmail;
                  send_resolved = true;
                  force_implicit_tls = true;
                }
              ];
            }
          ];
          inhibit_rules = [
            {
              source_matchers = ["severity=\"critical\""];
              target_matchers = ["severity=\"warning\""];
              equal = [
                "alertname"
                "instance"
              ];
            }
          ];
        };
      };
    };

    systemd.services.alertmanager.serviceConfig.LoadCredential = "smtp-password:${config.age.secrets.alertmanager-smtp-password.path}";

    services.nginx.virtualHosts."alertmanager.home.arpa" = {
      locations."/".proxyPass = "http://127.0.0.1:${toString ports.alertmanager}";
      extraConfig = ''
        allow 192.168.1.0/24;
        allow 100.64.0.0/10;
        deny all;
      '';
    };
  };
}
