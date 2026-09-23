# Syncthing — continuous file sync node for the homelab.
# GUI proxied at syncthing.home.arpa. Devices and folders are
# configured through the web UI on first run.
{
  ports,
  config,
  lib,
  ...
}: let
  username = config.modules.profile.username;
  homeDirectory = "/home/${username}";
in {
  config = lib.mkIf config.services.syncthing.enable {
    services.syncthing = {
      user = username;
      dataDir = homeDirectory;
      guiAddress = "127.0.0.1:${toString ports.syncthing}";
      openDefaultPorts = true;
    };

    services.nginx.virtualHosts."syncthing.home.arpa".locations."/" = {
      proxyPass = "http://127.0.0.1:${toString ports.syncthing}";
      proxyWebsockets = true;
    };
  };
}
