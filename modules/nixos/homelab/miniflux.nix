# Miniflux — self-hosted RSS reader.
# After first deploy, create the admin account:
#   sudo -u miniflux miniflux -create-admin
# Then migrate the credentials to agenix:
#   agenix -e secrets/miniflux-admin.age
#   (contents: ADMIN_USERNAME=juicy\nADMIN_PASSWORD=yourpassword)
# And set: adminCredentialsFile = config.age.secrets.miniflux-admin.path;
{
  config,
  lib,
  ...
}: let
  enabled = config.modules.homelab.miniflux.enable;
  inherit (config.modules) ports;
in {
  config = lib.mkIf enabled {
    services.miniflux = {
      enable = true;
      createDatabaseLocally = true;
      config = {
        LISTEN_ADDR = "127.0.0.1:${toString ports.miniflux}";
        BASE_URL = "http://rss.home.arpa";
        # Disable auto-admin — run `sudo -u miniflux miniflux -create-admin` after deploy.
        CREATE_ADMIN = 0;
        LOG_LEVEL = "warning";
      };
    };

    services.nginx.virtualHosts."rss.home.arpa".locations."/" = {
      proxyPass = "http://127.0.0.1:${toString ports.miniflux}";
    };
  };
}
