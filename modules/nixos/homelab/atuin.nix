{
  ports,
  config,
  lib,
  ...
}: let
  port = ports.atuin;
in {
  config = lib.mkIf config.services.atuin.enable {
    services = {
      atuin = {
        host = "127.0.0.1";
        inherit port;
        # Registration is a deployment-time bootstrap action, not a permanent
        # service default. Re-enable explicitly only while creating accounts.
        openRegistration = false;
      };

      nginx.virtualHosts."atuin.home.arpa".locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        proxyWebsockets = true;
      };
    };
  };
}
