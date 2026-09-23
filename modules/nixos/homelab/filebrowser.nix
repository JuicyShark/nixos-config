{
  ports,
  lib,
  config,
  ...
}: let
  username = config.modules.profile.username;
  rootPath = "/srv/chonk/family";
in {
  config = lib.mkIf config.services.filebrowser.enable {
    modules.system.media.enable = true;

    services.filebrowser = {
      user = "media";
      group = "media";
      settings = {
        address = "127.0.0.1";
        port = ports.filebrowser;
        root = rootPath;
      };
    };

    services.nginx.virtualHosts."files.home.arpa" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString ports.filebrowser}";
      };
      # Keep the UI private even when it is reached from an allowed network.
      extraConfig = ''
        allow 192.168.1.0/24;
        allow 100.64.0.0/10;
        deny all;
      '';
    };

    systemd.tmpfiles.rules = [
      "d ${rootPath} 0770 media media -"
      "d ${rootPath}/Shared 0770 media media -"
      "d ${rootPath}/Uploads 0770 media media -"
      "d ${rootPath}/Private 0770 media media -"
      "d ${rootPath}/Uploads/${username} 0770 media media -"
      "d ${rootPath}/Private/${username} 0770 media media -"
    ];

    systemd.services.filebrowser.unitConfig.RequiresMountsFor = [rootPath];
  };
}
