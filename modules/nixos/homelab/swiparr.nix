{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) str;
  cfg = config.modules.homelab.swiparr;
  ports = config.modules.ports;
in {
  options.modules.homelab.swiparr = {
    enable = mkEnableOption "Swiparr collaborative Jellyfin discovery";

    image = mkOption {
      type = str;
      default = "ghcr.io/m3sserstudi0s/swiparr:v1.5.1";
      description = "Pinned Swiparr OCI image.";
    };

    jellyfinUrl = mkOption {
      type = str;
      default = "http://${config.modules.homelab.jellyfin.host}:${toString ports.jellyfin}";
      description = "Internal Jellyfin URL used by the Swiparr server.";
    };

    jellyfinPublicUrl = mkOption {
      type = str;
      default = "https://jellyfin.nixlab.au";
      description = "Jellyfin URL opened by Swiparr clients.";
    };

    publicUrl = mkOption {
      type = str;
      default = "https://swiparr.nixlab.au";
      description = "Canonical public Swiparr URL.";
    };

    adminUsername = mkOption {
      type = str;
      default = config.modules.homelab.jellyfin.adminUsername;
      description = "Jellyfin username granted Swiparr administrator access.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation = {
      podman.enable = true;
      oci-containers = {
        backend = "podman";
        containers.swiparr = {
          inherit (cfg) image;
          pull = "newer";
          environment = {
            ADMIN_USERNAME = cfg.adminUsername;
            APP_PUBLIC_URL = cfg.publicUrl;
            DATABASE_URL = "file:/app/data/swiparr.db";
            HOSTNAME = "127.0.0.1";
            JELLYFIN_PUBLIC_URL = cfg.jellyfinPublicUrl;
            JELLYFIN_URL = cfg.jellyfinUrl;
            PORT = toString ports.swiparr;
            PROVIDER = "jellyfin";
            PROVIDER_LOCK = "true";
            USE_ANALYTICS = "false";
            USE_SECURE_COOKIES = "true";
          };
          volumes = ["/var/lib/swiparr:/app/data"];
          networks = ["host"];
          extraOptions = ["--security-opt=no-new-privileges"];
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/swiparr 0700 root root -"
    ];

    # HTTP access cannot carry Swiparr's secure session cookie. Keep the
    # familiar LAN hostname, but move browsers onto the canonical HTTPS URL.
    services.nginx.virtualHosts."swiparr.home.arpa".locations."/".return = "302 ${cfg.publicUrl}$request_uri";
  };
}
