# Deluge torrent client + mount dependency.
{
  lib,
  config,
  pkgs,
  ...
}: let
  homelabDeluge = config.modules.homelab.deluge.enable;

  inherit (config.modules) ports;
  mediaMountExists = builtins.hasAttr "/mnt/chonk" config.fileSystems;
  withMediaMount.serviceConfig.RequiresMountsFor = ["/mnt/chonk"];
  delugeWebConfigPreStart = ''
    set -eu

    config_dir="/var/lib/deluge/.config/deluge"
    web_conf="$config_dir/web.conf"
    hostlist_conf="$config_dir/hostlist.conf"
    web_password="$(${pkgs.coreutils}/bin/tr -d '\n' < "${config.age.secrets.deluge-pass.path}")"
    salt="c26ab3bbd8b137f99cd83c2c1c0963bcc1a35cad"
    pwd_sha1="$(${pkgs.coreutils}/bin/printf '%s%s' "$salt" "$web_password" | ${pkgs.coreutils}/bin/sha1sum | ${pkgs.coreutils}/bin/cut -d ' ' -f 1)"
    auth_line="$(${pkgs.gawk}/bin/awk -F: 'first == "" { first = $0 } $1 == "localclient" { print; found = 1; exit } END { if (!found && first != "") print first }' "${config.age.secrets.deluge-auth.path}")"
    daemon_user="''${auth_line%%:*}"
    daemon_rest="''${auth_line#*:}"
    daemon_password="''${daemon_rest%%:*}"

    ${pkgs.coreutils}/bin/mkdir -p "$config_dir"
    umask 077

    {
      ${pkgs.coreutils}/bin/printf '%s\n' '{"file": 1, "format": 1}'
      ${pkgs.coreutils}/bin/printf '%s\n' "{"
      ${pkgs.coreutils}/bin/printf '  "enabled_plugins": [],\n'
      ${pkgs.coreutils}/bin/printf '  "default_daemon": "local-deluge",\n'
      ${pkgs.coreutils}/bin/printf '  "pwd_salt": "%s",\n' "$salt"
      ${pkgs.coreutils}/bin/printf '  "pwd_sha1": "%s",\n' "$pwd_sha1"
      ${pkgs.coreutils}/bin/printf '  "session_timeout": 3600,\n'
      ${pkgs.coreutils}/bin/printf '  "sessions": {},\n'
      ${pkgs.coreutils}/bin/printf '  "sidebar_show_zero": false,\n'
      ${pkgs.coreutils}/bin/printf '  "sidebar_multiple_filters": true,\n'
      ${pkgs.coreutils}/bin/printf '  "show_session_speed": false,\n'
      ${pkgs.coreutils}/bin/printf '  "show_sidebar": true,\n'
      ${pkgs.coreutils}/bin/printf '  "theme": "gray",\n'
      ${pkgs.coreutils}/bin/printf '  "first_login": false\n'
      ${pkgs.coreutils}/bin/printf '%s\n' "}"
    } > "$web_conf"

    {
      ${pkgs.coreutils}/bin/printf '%s\n' '{"file": 3, "format": 1}'
      ${pkgs.coreutils}/bin/printf '{"hosts": [["local-deluge", "127.0.0.1", %s, "%s", "%s"]]}\n' \
        "${toString config.services.deluge.config.daemon_port}" \
        "$daemon_user" \
        "$daemon_password"
    } > "$hostlist_conf"
  '';
in {
  config = {
    age.secrets.deluge-auth = lib.mkIf config.services.deluge.enable {
      file = ../../../secrets/deluge-auth.age;
      mode = "0400";
      owner = config.services.deluge.user;
      group = config.services.deluge.group;
      path = "/var/lib/deluge/auth";
      symlink = false;
    };

    services.deluge = {
      enable = homelabDeluge;
      declarative = true;
      openFirewall = true; # opens only listen_ports; web UI stays nginx-only
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
        listen_ports = [
          ports.delugeIncoming
          ports.delugeIncoming
        ];
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
      delugeweb =
        lib.mkIf (config.services.deluge.web.enable && mediaMountExists)
        (lib.recursiveUpdate withMediaMount {
          preStart = lib.mkAfter delugeWebConfigPreStart;
        });
    };
  };
}
