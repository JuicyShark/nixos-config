# Zues networking: firewall, Cloudflare tunnel, Avahi, Samba, Tailscale, DNS stack.
{
  self,
  config,
  lib,
  pkgs,
  ...
}: let
  networkCfg = config.modules.network;
  endpoints = self.lib.${pkgs.stdenv.hostPlatform.system}.services.mkHomelabEndpoints {inherit config;};
  inherit (config.modules.system) username;

  # Cloudflared secret files. Keep these explicit so an untracked local secret
  # cannot change evaluation compared with a remote builder.
  # To migrate: agenix -e secrets/cloudflared-cert.age  (paste cert.pem content)
  #             agenix -e secrets/cloudflared-credentials.age (paste tunnel JSON content)
  certAgeFile = ../../secrets/cloudflared-cert.age;
  credentialsAgeFile = ../../secrets/cloudflared-credentials.age;
  useAgeCert = false;
  useAgeCredentials = false;
in {
  warnings =
    lib.optional (!useAgeCert) "zues cloudflared is using /home/${username}/.cloudflared/cert.pem because secrets/cloudflared-cert.age does not exist."
    ++ lib.optional (!useAgeCredentials) "zues cloudflared is using the user-home tunnel credentials because secrets/cloudflared-credentials.age does not exist.";

  # Rate-limit new TCP connections forwarded from WAN (enp1s0) to LAN clients.
  # Protects LAN from SYN floods originating on the upstream link.
  # Established/related traffic is already fast-patched by conntrack.
  networking.firewall.extraForwardRules = ''
    iifname "enp1s0" ct state new limit rate 500/second burst 1000 packets accept
    iifname "enp1s0" ct state new drop
  '';

  networking.firewall.interfaces = {
    br0 = {
      allowedTCPPorts = [
        445
        5357
        5358
      ];
      allowedUDPPorts = [
        3702
        5353
      ];
    };
    tailscale0.allowedTCPPorts = [445];
  };

  age.secrets = lib.mkMerge [
    (lib.mkIf useAgeCert {
      cloudflared-cert.file = certAgeFile;
      cloudflared-cert.owner = "cloudflared";
    })
    (lib.mkIf useAgeCredentials {
      cloudflared-credentials.file = credentialsAgeFile;
      cloudflared-credentials.owner = "cloudflared";
    })
  ];

  services = {
    cloudflared = {
      enable = true;
      tunnels."3c58774d-3e30-4151-a9e3-28daf4f5f307" = {
        default = "http_status:404";

        certificateFile =
          if useAgeCert
          then config.age.secrets.cloudflared-cert.path
          else "/home/${username}/.cloudflared/cert.pem";
        credentialsFile =
          if useAgeCredentials
          then config.age.secrets.cloudflared-credentials.path
          else "/home/${username}/.cloudflared/3c58774d-3e30-4151-a9e3-28daf4f5f307.json";

        ingress = endpoints.cloudflaredIngress;
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

    samba = {
      enable = true;
      openFirewall = false;
      settings = {
        global = {
          "server min protocol" = "SMB2";
          "disable netbios" = "yes";
          "smb ports" = "445";
          "interfaces" = "lo br0 tailscale0";
          "bind interfaces only" = "yes";
          "hosts allow" = "127. ${networkCfg.subnets.lan} ${networkCfg.subnets.tailscale}";
          "hosts deny" = "0.0.0.0/0";
          "map to guest" = "Bad User";
          "guest account" = "nobody";
        };

        FamilyShared = {
          path = "/srv/chonk/family/Shared";
          "browseable" = "yes";
          "read only" = "yes";
          "guest ok" = "yes";
          "force user" = "media";
          "force group" = "media";
          "create mask" = "0664";
          "directory mask" = "0775";
        };

        FamilyUploads = {
          path = "/srv/chonk/family/Uploads";
          "browseable" = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "force user" = "media";
          "force group" = "media";
          "create mask" = "0664";
          "directory mask" = "0775";
        };
      };
    };

    samba-wsdd = {
      enable = true;
      interface = "br0";
      openFirewall = false;
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
          networkCfg.hosts.zues
          "127.0.0.1"
        ];
        server = ["127.0.0.1#5353"];
        domain-needed = true;
        bogus-priv = true;

        domain = "home.arpa";
        local = "/home.arpa/";
        localise-queries = true;

        interface = ["br0"];
        except-interface = "enp1s0";
        bind-interfaces = true;
        expand-hosts = true;

        dhcp-ignore-names = true;
        dhcp-option = [
          "3,${networkCfg.hosts.zues}"
          "6,${networkCfg.hosts.zues}"
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
          inherit (endpoints) dnsAliases;
          # Hosts with both short and FQDN entries
          hosts = [
            {
              name = "dante";
              ip = networkCfg.hosts.dante;
            }
            {
              name = "leo";
              ip = networkCfg.hosts.leo;
            }
            {
              name = "zues";
              ip = networkCfg.hosts.zues;
            }
            {
              name = "hermes";
              ip = networkCfg.hosts.hermes;
            }
          ];
        in
          # router also resolves without domain suffix (legacy compat)
          ["/router/${networkCfg.hosts.zues}"]
          ++ map (svc: "/${svc}.home.arpa/${networkCfg.hosts.zues}") dnsAliases
          ++ lib.concatMap (h: [
            "/${h.name}/${h.ip}"
            "/${h.name}.home.arpa/${h.ip}"
          ])
          hosts;
      };
    };
  };
}
