# ACME / TLS module — wildcard cert for *.nixlab.au via Cloudflare DNS-01 challenge.
#
# Prerequisites (one-time setup):
#   1. Create a Cloudflare API token with Zone:DNS:Edit permission for nixlab.au
#   2. agenix -e secrets/cloudflare-token.env.age   (content: CF_DNS_API_TOKEN=<token>)
#   3. Set modules.acme.enable = true in the host config
#
# After activation, nginx virtualHosts can use:
#   useACMEHost = "nixlab.au";
#   forceSSL = true;
{
  lib,
  config,
  ...
}: let
  cfg = config.modules.acme;
in {
  options.modules.acme = {
    enable = lib.mkEnableOption "ACME wildcard cert for nixlab.au via Cloudflare DNS";

    email = lib.mkOption {
      type = lib.types.str;
      default = "maxwellb9879@gmail.com";
      description = "ACME account email";
    };

    extraDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional SANs beyond *.nixlab.au and nixlab.au";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets."cloudflare-token.env" = {
      file = ../../secrets/cloudflare-token.env.age;
      # Readable by the acme user
      group = "acme";
      mode = "0440";
    };

    security.acme = {
      acceptTerms = true;
      defaults = {
        inherit (cfg) email;
        dnsProvider = "cloudflare";
        credentialsFile = config.age.secrets."cloudflare-token.env".path;
      };

      certs."nixlab.au" = {
        domain = "nixlab.au";
        extraDomainNames = ["*.nixlab.au"] ++ cfg.extraDomains;
        # nginx needs read access to the cert
        group = "nginx";
      };
    };

    # nginx user needs to read ACME certs
    users.users.nginx.extraGroups = ["acme"];
  };
}
