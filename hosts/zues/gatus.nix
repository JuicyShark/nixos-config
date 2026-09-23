# Gatus uptime monitoring endpoint declarations for zues.
{
  ports,
  self,
  config,
  homelabFeatures,
  ...
}: let
  portsCfg = ports;
  endpoints = self.lib.services.mkHomelabEndpoints {
    inherit config;
    features = homelabFeatures;
  };
in {
  services.gatus.settings = {
    web = {
      address = "127.0.0.1";
      port = portsCfg.gatus;
    };
    storage = {
      type = "sqlite";
      path = "/var/lib/gatus/data.db";
    };
    metrics = true;
    ui.title = "nixlab status";
    endpoints =
      endpoints.statusPageEndpoints
      ++ [
        {
          name = "DNS home.arpa";
          group = "infrastructure";
          url = "127.0.0.1";
          interval = "1m";
          dns = {
            query-name = "status.home.arpa";
            query-type = "A";
          };
          conditions = [
            "[DNS_RCODE] == NOERROR"
            "[BODY] == 192.168.1.99"
          ];
        }
        {
          name = "DNS upstream";
          group = "infrastructure";
          url = "127.0.0.1";
          interval = "1m";
          dns = {
            query-name = "example.com";
            query-type = "A";
          };
          conditions = ["[DNS_RCODE] == NOERROR"];
        }
      ];
  };
}
