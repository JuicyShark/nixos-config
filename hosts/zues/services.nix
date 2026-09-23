{...}: {
  services = {
    prometheus.exporters.smartctl.devices = [
      "/dev/nvme0"
      "/dev/sdb"
      "/dev/sdd"
    ];

    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = ["/srv"];
    };

    irqbalance.enable = true;
    fstrim.enable = true;

    journald.settings.Journal = {
      SystemMaxUse = "500M";
      RuntimeMaxUse = "128M";
      MaxFileSec = "7day";
      RateLimitIntervalSec = "30s";
      RateLimitBurst = 1000;
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  systemd.services.samba-smbd.unitConfig.RequiresMountsFor = ["/srv/chonk"];
}
