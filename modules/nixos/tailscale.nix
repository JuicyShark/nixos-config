# Tailscale client — shared config for all NixOS hosts.
#
# Every host points at the self-hosted Headscale coordination server,
# accepts routes, and ignores Headscale DNS (we run our own via dnsmasq/unbound).
# Per-host differences (routing mode, advertised routes) are set via options.
{
  config,
  lib,
  ...
}: let
  cfg = config.modules.tailscale;
in {
  options.modules.tailscale = {
    enable = lib.mkEnableOption "Tailscale with self-hosted Headscale";

    loginServer = lib.mkOption {
      type = lib.types.str;
      default = "https://ts.nixlab.au";
      description = "Headscale coordination server URL";
    };

    routingMode = lib.mkOption {
      type = lib.types.enum ["client" "server" "both" "none"];
      default = "client";
      description = "Tailscale routing features mode";
    };

    advertiseRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Subnets to advertise to the Tailscale network";
    };

    acceptRoutes = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Accept routes advertised by other nodes";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = cfg.routingMode;
      extraUpFlags =
        ["--login-server=${cfg.loginServer}" "--accept-dns=false"]
        ++ lib.optional cfg.acceptRoutes "--accept-routes"
        ++ lib.optional (cfg.advertiseRoutes != [])
        "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}";
    };
  };
}
