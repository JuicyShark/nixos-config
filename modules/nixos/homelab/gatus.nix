# Gatus — declarative uptime monitor and status page.
{
  ports,
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services.gatus.enable {
    services.gatus.settings = {
      web.address = lib.mkDefault "127.0.0.1";
      web.port = lib.mkDefault ports.gatus;
      metrics = lib.mkDefault true;
    };

    services.nginx.virtualHosts."status.home.arpa".locations."/" = {
      proxyPass = "http://127.0.0.1:${toString ports.gatus}";
    };
  };
}
