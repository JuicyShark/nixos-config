# Leo backup policy: protect the shared smol data on Zues's separate chonk disk.
{
  config,
  pkgs,
  ...
}: let
  inherit (config.modules.profile) username;
  textfileDirectory = "/var/lib/node-exporter-textfiles";
  recordBackupSuccess = pkgs.writeShellScript "record-leo-smol-backup-success" ''
    set -euo pipefail
    temporary="$(${pkgs.coreutils}/bin/mktemp ${textfileDirectory}/leo-smol.prom.XXXXXX)"
    trap '${pkgs.coreutils}/bin/rm -f "$temporary"' EXIT
    printf '# HELP homelab_backup_last_success_timestamp_seconds Unix timestamp of the last successful backup and check.\n' > "$temporary"
    printf '# TYPE homelab_backup_last_success_timestamp_seconds gauge\n' >> "$temporary"
    printf 'homelab_backup_last_success_timestamp_seconds{backup="leo-smol"} %s\n' \
      "$(${pkgs.coreutils}/bin/date +%s)" >> "$temporary"
    ${pkgs.coreutils}/bin/chmod 0644 "$temporary"
    ${pkgs.coreutils}/bin/mv "$temporary" ${textfileDirectory}/leo-smol.prom
    trap - EXIT
  '';
  verifyRestore = pkgs.writeShellScript "verify-leo-smol-restore" ''
    set -euo pipefail
    restored=/run/restic-backups-leo-smol/flake-restore-check.nix
    ${pkgs.restic}/bin/restic \
      --repo /mnt/chonk/backups/leo-smol \
      --password-file ${config.age.secrets.restic-repository-password.path} \
      dump latest /srv/smol/nixos-config/flake.nix > "$restored"
    test -s "$restored"
  '';
in {
  age.secrets.restic-repository-password = {
    file = ../../secrets/restic-repository-password.age;
    mode = "0400";
  };

  services.restic.backups.leo-smol = {
    initialize = true;
    repository = "/mnt/chonk/backups/leo-smol";
    passwordFile = config.age.secrets.restic-repository-password.path;
    paths = [
      "/srv/smol/git"
      "/srv/smol/nixos-config"
    ];
    exclude = [
      "/srv/smol/nixos-config/.direnv"
      "/srv/smol/nixos-config/result"
      "/srv/smol/nixos-config/result-*"
    ];
    pruneOpts = [
      "--keep-daily 14"
      "--keep-weekly 8"
      "--keep-monthly 12"
    ];
    checkOpts = ["--read-data-subset=5%"];
    timerConfig = {
      OnCalendar = "*-*-* 04:30:00";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };

  systemd.services.restic-backups-leo-smol = {
    unitConfig.RequiresMountsFor = [
      "/srv/smol"
      "/mnt/chonk"
    ];
    serviceConfig = {
      ExecStartPost = [
        verifyRestore
        recordBackupSuccess
      ];
    };
  };

  # Zues is all_squash-mapped to Leo's primary user. Create the repository
  # parent on the exporting host so remote root does not hit a root-owned 0755
  # directory before Restic can initialize its repositories.
  systemd.tmpfiles.rules = [
    "d /srv/smol/backups 0700 ${username} users -"
  ];
}
