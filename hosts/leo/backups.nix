# Leo backup policy: protect the shared smol data on Zues's separate chonk disk.
{config, ...}: {
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

  systemd.services.restic-backups-leo-smol.unitConfig.RequiresMountsFor = [
    "/srv/smol"
    "/mnt/chonk"
  ];
}
