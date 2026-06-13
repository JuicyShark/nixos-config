# Zues services: backups, disk health, system tuning, journald, systemd units.
{
  config,
  lib,
  pkgs,
  ...
}: let
  postgresqlDatabases = config.services.postgresql.ensureDatabases;
  postgresqlBackupUnits = map (db: "postgresqlBackup-${db}.service") postgresqlDatabases;
  startUnit = unit: "systemctl start ${unit}";
  sqliteBackup = source: target: ''
    if [ -f ${source} ]; then
      install -d -m 0700 ${builtins.dirOf target}
      ${pkgs.sqlite}/bin/sqlite3 ${source} ".backup '${target}'"
    fi
  '';
in {
  services = {
    postgresqlBackup = lib.mkIf config.services.postgresql.enable {
      enable = true;
      backupAll = false;
      databases = postgresqlDatabases;
      location = "/var/backup/postgresql";
      startAt = "*-*-* 02:10:00";
      compression = "zstd";
    };

    restic.backups = {
      services = {
        initialize = true;
        repository = "/srv/chonk/backups/restic-services";
        passwordFile = "/var/lib/restic-services/password";
        paths = [
          "/var/lib/vaultwarden"
          "/var/lib/jellyfin"
          "/var/lib/sonarr"
          "/var/lib/radarr"
          "/var/lib/lidarr"
          "/var/lib/prowlarr"
          "/var/lib/headscale"
          "/var/backup/gatus"
          "/var/backup/grafana"
          "/var/backup/headscale"
          "/var/backup/postgresql"
          "/var/backup/vaultwarden"
        ];
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 3"
        ];
        checkOpts = ["--with-cache"];
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = "2h";
          Persistent = true;
        };
        backupPrepareCommand = ''
          install -d -m 0700 /var/lib/restic-services
          if [ ! -s /var/lib/restic-services/password ]; then
            umask 0077
            tr -dc 'A-Za-z0-9!@#$%^&*()-_=+[]{}' </dev/urandom | head -c 48 > /var/lib/restic-services/password
          fi
          ${sqliteBackup "/var/lib/gatus/data.db" "/var/backup/gatus/data.db"}
          ${sqliteBackup "/var/lib/grafana/data/grafana.db" "/var/backup/grafana/grafana.db"}
          ${sqliteBackup "/var/lib/headscale/db.sqlite" "/var/backup/headscale/db.sqlite"}
          ${lib.optionalString (config.services.vaultwarden.enable && config.services.vaultwarden.backupDir != null) (startUnit "backup-vaultwarden.service")}
          ${lib.optionalString (config.services.postgresqlBackup.enable && postgresqlDatabases != []) (
            lib.concatStringsSep "\n" (map startUnit postgresqlBackupUnits)
          )}
        '';
      };

      family-share = {
        initialize = true;
        repository = "/srv/chonk/backups/restic-family";
        passwordFile = "/var/lib/restic-family/password";
        paths = ["/srv/chonk/family"];
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 6"
        ];
        checkOpts = ["--with-cache"];
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = "1h";
          Persistent = true;
        };
        backupPrepareCommand = ''
          install -d -m 0700 /var/lib/restic-family
          if [ ! -s /var/lib/restic-family/password ]; then
            umask 0077
            tr -dc 'A-Za-z0-9!@#$%^&*()-_=+[]{}' </dev/urandom | head -c 48 > /var/lib/restic-family/password
          fi
        '';
      };
    };

    prometheus.exporters.smartctl.devices = [
      "/dev/nvme0"
      "/dev/nvme1"
      "/dev/sdd"
      "/dev/sde"
    ];

    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = ["/srv"];
    };

    irqbalance.enable = true;
    fstrim.enable = true;

    journald.extraConfig = ''
      SystemMaxUse=500M
      RuntimeMaxUse=128M
      MaxFileSec=7day
      RateLimitInterval=30s
      RateLimitBurst=1000
    '';
  };

  zramSwap = {
    enable = lib.mkForce true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  systemd.services = {
    nixos-upgrade.serviceConfig.RequiresMountsFor = [
      "/srv"
      "/mnt/chonk"
    ];
    samba-smbd.serviceConfig.RequiresMountsFor = ["/srv/chonk"];
    restic-backups-family-share.serviceConfig.RequiresMountsFor = ["/srv/chonk"];
    restic-backups-services.serviceConfig.RequiresMountsFor = ["/srv/chonk"];
  };

  systemd.tmpfiles.rules = [
    "d /srv/chonk/backups 0750 media media -"
    "d /srv/chonk/backups/restic-family 0750 media media -"
    "d /srv/chonk/backups/restic-services 0750 root root -"
    "d /var/lib/restic-family 0700 root root -"
    "d /var/lib/restic-services 0700 root root -"
  ];
}
