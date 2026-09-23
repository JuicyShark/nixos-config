{
  ports,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.homelab.swiparr;
in {
  options.modules.homelab.swiparr = {
    enable = mkEnableOption "Swiparr collaborative Jellyfin discovery";
  };

  config = mkIf cfg.enable {
    virtualisation = {
      podman.enable = true;
      oci-containers = {
        backend = "podman";
        containers.swiparr = {
          image = "ghcr.io/m3sserstudi0s/swiparr:v1.5.1";
          # Updates must be reviewed and deployed explicitly; do not replace
          # the running image merely because a mutable tag changed upstream.
          pull = "missing";
          environment = {
            ADMIN_USERNAME = config.modules.profile.username;
            APP_PUBLIC_URL = "https://swiparr.nixlab.au";
            DATABASE_URL = "file:/app/data/swiparr.db";
            HOSTNAME = "127.0.0.1";
            JELLYFIN_PUBLIC_URL = "https://jellyfin.nixlab.au";
            JELLYFIN_URL = "http://192.168.1.52:${toString ports.jellyfin}";
            PORT = toString ports.swiparr;
            PROVIDER = "jellyfin";
            PROVIDER_LOCK = "true";
            USE_ANALYTICS = "false";
            USE_SECURE_COOKIES = "true";
          };
          volumes = ["/var/lib/swiparr:/app/data"];
          networks = ["host"];
          # Keep a third-party container from starving DNS, nginx, and
          # monitoring on the homelab host.
          extraOptions = [
            "--security-opt=no-new-privileges"
            "--memory=2g"
            "--cpus=2"
            "--pids-limit=512"
          ];
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/swiparr 0700 root root -"
    ];

    # HTTP access cannot carry Swiparr's secure session cookie. Keep the
    # familiar LAN hostname, but move browsers onto the canonical HTTPS URL.
    services.nginx.virtualHosts."swiparr.home.arpa".locations."/".return = "302 https://swiparr.nixlab.au$request_uri";
  };
}
