# Zues networking: firewall, Cloudflare tunnel, Avahi, and DNS stack.
{
  self,
  config,
  lib,
  ...
}: let
  endpoints = self.lib.services.mkHomelabEndpoints {
    inherit config;
  };
in {
  networking.firewall.interfaces = {
    br0 = {
      allowedTCPPorts = [
        53
        80
        config.modules.ports.loki
      ];
      allowedUDPPorts = [
        53
        67
        5353
      ];
    };
    tailscale0 = {
      allowedTCPPorts = [
        53
        80
        config.modules.ports.loki
      ];
      allowedUDPPorts = [53];
    };
  };

  age.secrets = {
    cloudflared-cert = {
      file = ../../secrets/cloudflared-cert.age;
      owner = "cloudflared";
    };
    cloudflared-credentials = {
      file = ../../secrets/cloudflared-credentials.age;
      owner = "cloudflared";
    };
  };

  services = {
    cloudflared = {
      enable = true;
      tunnels."3c58774d-3e30-4151-a9e3-28daf4f5f307" = {
        default = "http_status:404";

        certificateFile = config.age.secrets.cloudflared-cert.path;
        credentialsFile = config.age.secrets.cloudflared-credentials.path;

        ingress = endpoints.publicTunnelIngress;
      };
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      allowInterfaces = ["br0"];
      openFirewall = false;
      publish = {
        enable = true;
        userServices = true;
      };
    };

    unbound = {
      enable = true;
      localControlSocketPath = "/run/unbound/unbound.ctl";
      settings = {
        server = {
          interface = ["127.0.0.1@5353"];
          # Only loopback clients can reach unbound — dnsmasq forwards on their behalf.
          access-control = ["127.0.0.0/8 allow"];
          verbosity = 1;
          # Serve stale cached answers if upstream is unreachable rather than
          # blocking — prevents dnsmasq from stalling the whole LAN on upstream failure.
          serve-expired = true;
          serve-expired-ttl = 3600;
        };
        forward-zone = [
          {
            name = ".";
            forward-addr = [
              "1.1.1.1"
              "1.0.0.1"
            ];
          }
        ];
      };
    };

    dnsmasq = {
      enable = true;
      alwaysKeepRunning = true;
      resolveLocalQueries = true;
      settings = {
        no-resolv = true;
        listen-address = [
          "192.168.1.99"
          "127.0.0.1"
        ];
        server = ["127.0.0.1#5353"];
        domain-needed = true;
        bogus-priv = true;

        domain = "home.arpa";
        local = [
          "/home.arpa/"
          "/mc.nixlab.au/"
        ];
        localise-queries = true;

        interface = [
          "br0"
          "tailscale0"
        ];
        except-interface = "enp1s0";
        # tailscale0 is created dynamically by tailscaled.
        bind-dynamic = true;
        expand-hosts = true;

        dhcp-ignore-names = true;
        dhcp-option = [
          "3,192.168.1.99"
          "6,192.168.1.99"
          "15,home.arpa"
        ];
        dhcp-range = [
          "192.168.1.10,192.168.1.98,12h"
          "192.168.1.100,192.168.1.254,24h"
        ];
        dhcp-host = [
          "D8:5E:D3:AF:EE:02,machop,set:machop,192.168.1.54"
          "86:22:d4:1a:f8:0c,machop-iphone,192.168.1.53"
          "D0:11:E5:9A:85:20,imac-machop,192.168.1.52"
          "34:C9:3D:1E:4C:1D,quagsire-laptop,192.168.1.120"
          "D8:BB:C1:92:7B:1D,viridian,192.168.1.150"
          "04:E4:B6:13:C0:EC,viridian-monitor,192.168.1.152"
          "5C:84:3C:69:14:11,evee-ps5,192.168.1.230"
          # Smart Home
          "68:FE:71:A5:36:38,wled-double,192.168.1.12"
          "78:42:1C:F2:79:1C,big-grow-light-plug,192.168.1.18"
          "78:42:1C:F2:79:7E,smart-plug2,192.168.1.19"
        ];

        address = let
          # All services running on zues, exposed at <name>.home.arpa
          inherit (endpoints) homeArpaServiceAliases;
          # Hosts with both short and FQDN entries
          hosts = [
            {
              name = "dante";
              ip = "192.168.1.60";
            }
            {
              name = "leo";
              ip = "192.168.1.54";
            }
            {
              name = "machop";
              ip = "192.168.1.52";
            }
            {
              name = "hass";
              ip = "192.168.1.49";
            }
            {
              name = "zues";
              ip = "192.168.1.99";
            }
            {
              name = "hermes";
              ip = "192.168.1.56";
            }
          ];
        in
          # router also resolves without domain suffix (legacy compat)
          ["/router/192.168.1.99"]
          ++ ["/mc.nixlab.au/192.168.1.52"]
          ++ map (svc: "/${svc}.home.arpa/192.168.1.99") homeArpaServiceAliases
          ++ lib.concatMap (h: [
            "/${h.name}/${h.ip}"
            "/${h.name}.home.arpa/${h.ip}"
          ])
          hosts;
      };
    };
  };
}
