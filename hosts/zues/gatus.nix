# Gatus uptime monitoring endpoint declarations for zues.
{
  self,
  config,
  pkgs,
  ...
}: let
  portsCfg = config.modules.ports;
  endpoints = self.lib.${pkgs.stdenv.hostPlatform.system}.services.mkHomelabEndpoints {inherit config;};
in {
  modules.homelab.gatus.settings = {
    web = {
      address = "127.0.0.1";
      port = portsCfg.gatus;
    };
    storage = {
      type = "sqlite";
      path = "/var/lib/gatus/data.db";
    };
    ui.title = "nixlab status";
    endpoints = endpoints.gatusEndpoints;
  };
}
