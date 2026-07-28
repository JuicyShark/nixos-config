{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption;
  inherit (config.modules) ports;
  cfg = config.modules.homelab.filebrowser;
  username = config.modules.profile.username;
  rootPath = "/srv/chonk/family";
in {
  options.modules.homelab.filebrowser.enable = mkEnableOption "Filebrowser web file manager";

  config = lib.mkIf cfg.enable {
    services.filebrowser = {
      enable = true;
      openFirewall = false;
      user = "media";
      group = "media";
      settings = {
        address = "127.0.0.1";
        port = ports.filebrowser;
        root = rootPath;
        noauth = false;
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

    systemd.services.filebrowser.serviceConfig.RequiresMountsFor = ["/srv/chonk"];
  };
}
