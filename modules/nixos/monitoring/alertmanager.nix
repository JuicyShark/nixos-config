# Prometheus Alertmanager with SMTP credentials derived at runtime.
{
  config,
  lib,
  pkgs,
  ...
}: let
  enabled = config.modules.monitoring.enable;
  inherit (config.modules) ports;
  smtpEmail = config.modules.homelab.smtpEmail;
  smtpEnvironment = config.age.secrets."alertmanager-smtp.env".path;
  smtpPasswordFile = "/var/lib/alertmanager/smtp-password";

  prepareSmtpPassword = pkgs.writeShellScript "alertmanager-prepare-smtp-password" ''
    set -euo pipefail
    set -a
    . ${smtpEnvironment}
    set +a

    : "''${SMTP_PASSWORD:?alertmanager SMTP_PASSWORD is missing}"
    umask 077
    printf '%s' "$SMTP_PASSWORD" > ${smtpPasswordFile}
    ${pkgs.coreutils}/bin/chown --reference=/var/lib/alertmanager ${smtpPasswordFile}
  '';
in {
  config = lib.mkIf enabled {
    assertions = [
      {
        assertion = smtpEmail != "";
        message = "modules.monitoring requires modules.homelab.smtpEmail for Alertmanager notifications";
      }
    ];

    # Reuse the encrypted SMTP source, but only copy SMTP_PASSWORD into the
    # Alertmanager-owned state directory. The daemon never receives the full
    # Vaultwarden environment.
    age.secrets."alertmanager-smtp.env" = {
      file = ../../../secrets/vaultwarden.env.age;
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
        checkConfig = false;
        webExternalUrl = "http://alertmanager.home.arpa";
        configuration = {
          global = {
            smtp_smarthost = "smtp.gmail.com:465";
            smtp_from = smtpEmail;
            smtp_auth_username = smtpEmail;
            smtp_auth_password_file = smtpPasswordFile;
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
            routes = [
              {
                receiver = "email";
                matchers = ["severity=\"critical\""];
                repeat_interval = "4h";
              }
            ];
          };
          receivers = [
            {
              name = "email";
              email_configs = [
                {
                  to = smtpEmail;
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

    systemd.services.alertmanager.serviceConfig.ExecStartPre =
      lib.mkBefore ["+${prepareSmtpPassword}"];

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
