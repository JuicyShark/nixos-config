# Deluge torrent client + mount dependency.
{
  lib,
  config,
  ...
}: let
  homelabDeluge = config.modules.homelab.deluge.enable;

  inherit (config.modules) ports;

  mediaMountExists = builtins.hasAttr "/mnt/chonk" config.fileSystems;
  withMediaMount.serviceConfig.RequiresMountsFor = ["/mnt/chonk"];
in {
  config = {
    age.secrets.deluge-auth = lib.mkIf config.services.deluge.enable {
      file = ../../../secrets/deluge-auth.age;
      owner = "media";
    };

    services.deluge = {
      enable = homelabDeluge;
      declarative = true;
      openFirewall = false; # allow_remote=false; nginx proxies the web UI
      user = "media";
      group = "media";
      authFile = config.age.secrets.deluge-auth.path;
      config = {
        copy_torrent_file = true;
        move_completed = true;
        torrentfiles_location = "/mnt/chonk/media/torrent/files";
        download_location = "/mnt/chonk/media/torrent/downloading";
        move_completed_path = "/mnt/chonk/media/torrent/data";
        dont_count_slow_torrents = true;
        max_active_seeding = 50;
        max_active_limit = 50;
        max_active_downloading = 4;
        max_connections_global = 150;
        max_upload_speed = 4000;
        max_download_speed = 75000;
        share_ratio_limit = 2;
        allow_remote = false;
        daemon_port = ports.delugeDaemon;
        random_port = false;
        enabled_plugins = ["Label"];
      };

      web = {
        enable = homelabDeluge;
        port = ports.delugeWeb;
        openFirewall = false; # nginx proxies deluge.home.arpa
      };
    };

    systemd.services = {
      deluged = lib.mkIf (config.services.deluge.enable && mediaMountExists) withMediaMount;
      deluge-web = lib.mkIf (config.services.deluge.web.enable && mediaMountExists) withMediaMount;
    };
  };
}
