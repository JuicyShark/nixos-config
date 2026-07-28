{
  config,
  lib,
  pkgs,
  ...
}: let
  postgresqlDatabases = config.services.postgresql.ensureDatabases;
  postgresqlBackupUnits = map (db: "postgresqlBackup-${db}.service") postgresqlDatabases;
  startUnit = unit: "${pkgs.systemd}/bin/systemctl start ${unit}";
  sqliteBackup = source: target: ''
    if [ -f ${source} ]; then
      ${pkgs.coreutils}/bin/install -d -m 0700 ${builtins.dirOf target}
      ${pkgs.sqlite}/bin/sqlite3 ${source} ".backup '${target}'"
    fi
  '';
  retention = [
    "--keep-daily 14"
    "--keep-weekly 8"
    "--keep-monthly 12"
  ];
in {
  age.secrets.restic-repository-password = {
    file = ../../secrets/restic-repository-password.age;
    mode = "0400";
  };

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
      zues-services = {
        initialize = true;
        repository = "/mnt/smol/backups/zues-services";
        passwordFile = config.age.secrets.restic-repository-password.path;
        paths = [
          "/var/backup/postgresql"
          "/var/backup/sqlite"
          "/var/backup/vaultwarden"
          "/var/lib/lidarr"
          "/var/lib/prowlarr"
          "/var/lib/qBittorrent"
          "/var/lib/radarr"
          "/var/lib/seerr"
          "/var/lib/sonarr"
        ];
        exclude = [
          "*/logs/*"
          "*/MediaCover/*"
          "*/cache/*"
        ];
        pruneOpts = retention;
        checkOpts = ["--read-data-subset=5%"];
        timerConfig = {
          OnCalendar = "*-*-* 03:00:00";
          RandomizedDelaySec = "30m";
          Persistent = true;
        };
        backupPrepareCommand = ''
          #!${pkgs.runtimeShell}
          set -euo pipefail

          ${pkgs.coreutils}/bin/install -d -m 0700 /mnt/smol/backups/zues-services
          ${pkgs.coreutils}/bin/install -d -m 0700 /var/backup/sqlite
          ${sqliteBackup "/var/lib/gatus/data.db" "/var/backup/sqlite/gatus.db"}
          ${sqliteBackup "/var/lib/grafana/data/grafana.db" "/var/backup/sqlite/grafana.db"}
          ${lib.optionalString config.services.vaultwarden.enable (startUnit "backup-vaultwarden.service")}
          ${lib.optionalString (config.services.postgresqlBackup.enable && postgresqlDatabases != []) (
            lib.concatStringsSep "\n" (map startUnit postgresqlBackupUnits)
          )}

          if ${pkgs.systemd}/bin/systemctl is-active --quiet qbittorrent.service; then
            ${pkgs.coreutils}/bin/touch /run/restic-backups-zues-services/qbittorrent-was-active
            ${pkgs.systemd}/bin/systemctl stop qbittorrent.service
          fi
        '';
        backupCleanupCommand = ''
          #!${pkgs.runtimeShell}
          set -euo pipefail

          if [ -e /run/restic-backups-zues-services/qbittorrent-was-active ]; then
            ${pkgs.systemd}/bin/systemctl start qbittorrent.service
          fi
        '';
      };

      zues-family = {
        initialize = true;
        repository = "/mnt/smol/backups/zues-family";
        passwordFile = config.age.secrets.restic-repository-password.path;
        paths = ["/srv/chonk/family"];
        pruneOpts = retention;
        checkOpts = ["--read-data-subset=5%"];
        timerConfig = {
          OnCalendar = "*-*-* 04:00:00";
          RandomizedDelaySec = "30m";
          Persistent = true;
        };
        backupPrepareCommand = ''
          #!${pkgs.runtimeShell}
          set -euo pipefail
          ${pkgs.coreutils}/bin/install -d -m 0700 /mnt/smol/backups/zues-family
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
    samba-smbd.unitConfig.RequiresMountsFor = ["/srv/chonk"];
    restic-backups-zues-family.unitConfig.RequiresMountsFor = [
      "/srv/chonk"
      "/mnt/smol"
    ];
    restic-backups-zues-services.unitConfig.RequiresMountsFor = [
      "/srv"
      "/mnt/smol"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/chonk/backups 0750 media media -"
    "d /srv/chonk/backups/leo-smol 0750 media media -"
    "d /var/backup/sqlite 0700 root root -"
  ];
}
