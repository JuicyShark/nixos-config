{ config, lib, pkgs, ... }: let
  cfg = config.modules.router;
  in
{
  options.modules.router = {
    enable = lib.mkEnableOption "Enable Router Config";
    networking = {
      ipv4 = lib.mkOption {
        type = lib.types.str;
        default = "192.168.54.99";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      networkmanager.enable = false;
      nameservers = ["1.1.1.1"];
      wlanInterfaces.wlan.device = "enp1s0";
      defaultGateway = {
        interface = "enp1s0";
        address = "167.179.174.178";
      };


      wireless.enable = false;

      firewall = {
        enable = true;
        trustedInterfaces = ["br0"];
        allowedTCPPorts = [8080 8521];

        # Forward Wiregaurd Traffic
        extraCommands = ''
          iptables -A FORWARD -i wg0 -o br0 -j ACCEPT
          iptables -A FORWARD -i br0 -o wg0 -m state --state RELATED, ESTABLISHED -j ACCEPT

          iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
          iptables -A FORWARD -i br0 -o enp1s0 -j ACCEPT
          iptables -A FORWARD -i enp1s0 -o br0 -p tcp --dport 8096 -j ACCEPT
        '';
      };

      # all ethernet ports and wireguard0 address translated for use on wlan connection
      nat = {
        enable = true;
        internalInterfaces = ["br0" "wg0"];
        externalInterface = "enp1s0";
      };

      bridges.br0.interfaces = [
        "enp2s0"
        "enp3s0"
        "enp4s0"
      ];
      interfaces = {
        # do i need this with static IP on wlan?
        enp1s0.useDHCP = true;

        br0.ipv4.addresses = [
          {
            address = "192.168.54.99";
            prefixLength = 24;
          }
        ];
      };
     /* wireguard.enable = false;
      wireguard.interfaces = {
      wg0 = {
        ips = ["192.168.55.99/32"];
        listenPort = 51820;
        privateKeyFile = config.sops.secrets.wireguardKey.path;


           peers = [
          {
            publicKey = "qduADI4ktNoqnC6MJ9EbSLRjz6gox6ChPFrCibRpWUU=";
            allowedIPs = [ "192.168.55.54/32" ];
          }
        ];

      };
    };*/
    };

    /*
    security.acme = {
      acceptTerms = true;
      defaults.email = "maxwellb9879@gmail.com";
    };
    */
    services = {
      nginx = {
        enable = true;

        virtualHosts = {
          "jellyfin.nixlab.au" = {
            listen = [ { addr = "0.0.0.0"; port = 8080; } ];
            locations."/" = {
              proxyPass = "http://${config.modules.server.networking.ipv4}:8096";
              proxyWebsockets = true;

              extraConfig = ''
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
              '';
            };
          };

          "pass.nixlab.au" = {
            #forceSSL = true;
            #enableACME = false;
            listen = [ { addr = "0.0.0.0"; port = 8521; } ];
            locations."/" = {
              proxyPass = "http://${config.modules.server.networking.ipv4}:8521";
              proxyWebsockets = true;

              extraConfig = ''
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
              '';
            };
          };
        };
      };

      dnsmasq = {
    enable = true;
    alwaysKeepRunning = true;
    resolveLocalQueries = true;
    settings = {
      # General
      listen-address = [
        "127.0.0.1"
        "192.168.54.99"
      ];
      server = ["1.1.1.1"];
      domain-needed = true;
      bogus-priv = true;

      # Domain
      domain = "${toString config.networking.domain}";
      local = "/nixlab.local/";
      #   enable-ra = true;
      localise-queries = true;

      interface = [
        "br0"
      ];

      except-interface = "enp1s0";
      #     bind-interfaces = true;
      expand-hosts = true;

      #DHCP
      dhcp-option = [
        "option:router,0.0.0.0"
        "6,0.0.0.0"
      ];

      dhcp-range = [
        "::,constructor:enp1s0,ra-stateless,ra-names"
        "192.168.54.30,192.168.54.254,5m"
      ];

      dhcp-host = [
        "11:22:33:44:55:66,leo,192.168.54.54"
        "11:22:33:44:55:66,hermes,192.168.54.56"
        "11:22:33:44:55:66,dante,192.168.54.60"
      ];

      address = [
        "/router.nixlab.au/192.168.54.98"
        "/dante.nixlab.au/192.168.54.60"
        "/leo.nixlab.au/192.168.54.54"
        "/hermes.nixlab.au/192.168.54.56"
      ];
    };
  };
};
};
}

