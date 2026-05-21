{
  config,
  lib,
  ...
}: let
  cfg = config.modules.homelab.immich;
  inherit (config.modules) ports;
  externalDomain =
    if cfg.publicDomain != null
    then "https://${cfg.publicDomain}"
    else "http://${cfg.domain}";
in {
  config = lib.mkIf cfg.enable {
    services = {
      immich = {
        enable = true;
        host = "127.0.0.1";
        port = ports.immich;
        openFirewall = false;
        inherit (cfg) mediaLocation;
        settings = {
          server.externalDomain = externalDomain;
        };
      };

      nginx.virtualHosts.${cfg.domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString ports.immich}";
          proxyWebsockets = true;
          extraConfig = ''
            client_max_body_size 0;
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
          '';
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${toString cfg.mediaLocation} 0750 ${config.services.immich.user} ${config.services.immich.group} -"
    ];

    systemd.services = {
      immich-server.unitConfig.RequiresMountsFor = ["/srv/chonk"];
      immich-machine-learning.unitConfig.RequiresMountsFor = ["/srv/chonk"];
    };
  };
}
