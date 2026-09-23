# Jellyfin playback analytics, available only through the LAN nginx frontend.
{
  ports,
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.homelab.jellystat;
  databaseName = "jellystat";
  databaseUser = "jellystat";
  databasePasswordFile = config.age.secrets.jellystat-db-password.path;
  jwtSecretFile = config.age.secrets.jellystat-jwt-secret.path;
  prepareDatabaseCredentials = pkgs.writeShellScript "prepare-jellystat-database-credentials" ''
    set -euo pipefail

    password="$(${pkgs.coreutils}/bin/tr -d '\n' < ${databasePasswordFile})"
    if ! [[ "$password" =~ ^[[:xdigit:]]{64}$ ]]; then
      echo "Jellystat database password must be exactly 64 hexadecimal characters" >&2
      exit 1
    fi

    printf "ALTER ROLE ${databaseUser} WITH PASSWORD '%s';\n" "$password" \
      | ${pkgs.util-linux}/bin/runuser -u postgres -- \
          ${lib.getExe' config.services.postgresql.package "psql"} \
          --dbname postgres \
          --set ON_ERROR_STOP=1
  '';
in {
  options.modules.homelab.jellystat = {
    enable = lib.mkEnableOption "LAN-only Jellystat analytics for Jellyfin";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.modules.homelab.jellyfin.enable;
        message = "modules.homelab.jellystat requires modules.homelab.jellyfin";
      }
      {
        assertion = config.services.postgresql.enable;
        message = "modules.homelab.jellystat requires native PostgreSQL";
      }
    ];

    age.secrets = {
      jellystat-db-password = {
        file = ../../../secrets/jellystat-db-password.age;
        mode = "0400";
      };
      jellystat-jwt-secret = {
        file = ../../../secrets/jellystat-jwt-secret.age;
        mode = "0400";
      };
    };

    services.postgresql = {
      ensureDatabases = [databaseName];
      ensureUsers = [
        {
          name = databaseUser;
          ensureDBOwnership = true;
          ensureClauses = {
            login = true;
            superuser = false;
            createrole = false;
            createdb = false;
            replication = false;
          };
        }
      ];
      authentication = lib.mkAfter ''
        local ${databaseName} ${databaseUser} scram-sha-256
      '';
    };

    virtualisation = {
      podman.enable = true;
      oci-containers = {
        backend = "podman";
        containers.jellystat = {
          image = "docker.io/cyfershepard/jellystat@sha256:c4e2dfa8bddf8d5ac3a675d7202f71a54dcfe3540cc186899d9201e0fe701fa5";
          pull = "missing";
          environment = {
            FILE__JWT_SECRET = "/run/secrets/jellystat-jwt-secret";
            FILE__POSTGRES_PASSWORD = "/run/secrets/jellystat-db-password";
            JF_USE_WEBSOCKETS = "true";
            JS_LISTEN_IP = "0.0.0.0";
            POSTGRES_DB = databaseName;
            POSTGRES_IP = "/run/postgresql";
            POSTGRES_PORT = "5432";
            POSTGRES_SSL_ENABLED = "false";
            POSTGRES_USER = databaseUser;
            TZ = "Australia/Brisbane";
          };
          volumes = [
            "/var/lib/jellystat:/app/backend/backup-data"
            "/run/postgresql:/run/postgresql:ro"
            "${databasePasswordFile}:/run/secrets/jellystat-db-password:ro"
            "${jwtSecretFile}:/run/secrets/jellystat-jwt-secret:ro"
          ];
          ports = ["127.0.0.1:${toString ports.jellystat}:3000"];
          extraOptions = [
            "--cap-drop=all"
            "--security-opt=no-new-privileges"
          ];
        };
      };
    };

    systemd = {
      services = {
        jellystat-postgresql-credentials = {
          description = "Provision Jellystat's restricted PostgreSQL login";
          after = ["postgresql-setup.service"];
          requires = ["postgresql-setup.service"];
          before = ["podman-jellystat.service"];
          requiredBy = ["podman-jellystat.service"];
          restartTriggers = [config.age.secrets.jellystat-db-password.file];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = prepareDatabaseCredentials;
            RemainAfterExit = true;
          };
        };
        podman-jellystat.restartTriggers = [config.age.secrets.jellystat-db-password.file];
      };
      tmpfiles.rules = [
        "d /var/lib/jellystat 0700 root root -"
      ];
    };

    services.nginx.virtualHosts."jellystat.home.arpa".locations."/" = {
      proxyPass = "http://127.0.0.1:${toString ports.jellystat}";
      proxyWebsockets = true;
    };
  };
}
