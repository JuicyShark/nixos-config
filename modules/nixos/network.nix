# Network Configuration
#
# Centralizes all network configuration including host IP addresses,
# subnets, and DNS settings. This eliminates hardcoded IPs throughout
# the configuration.
#
# Usage:
#   targets = ["${config.modules.network.hosts.zues}:9091"];
#   subnet = config.modules.network.subnets.lan;

{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkOption;
  inherit (lib.types) str;
in
{
  options.modules.network = {
    # Subnet configurations
    subnets = {
      lan = mkOption {
        type = str;
        default = "192.168.1.0/24";
        description = "Home LAN subnet";
      };

      cloudflare1 = mkOption {
        type = str;
        default = "172.64.0.0/13";
        description = "Cloudflare IP range 1";
      };

      cloudflare2 = mkOption {
        type = str;
        default = "131.0.72.0/22";
        description = "Cloudflare IP range 2";
      };
    };

    # Host IP addresses
    hosts = {
      # Main hosts
      leo = mkOption {
        type = str;
        default = "192.168.1.54";
        description = "Leo desktop (main workstation)";
      };

      zues = mkOption {
        type = str;
        default = "192.168.1.99";
        description = "Zues homelab server";
      };

      fallarbor = mkOption {
        type = str;
        default = "192.168.1.100";
        description = "Fallarbor server";
      };

      # Mobile and personal devices
      machop = mkOption {
        type = str;
        default = "192.168.1.54";
        description = "Machop device";
      };

      machop-iphone = mkOption {
        type = str;
        default = "192.168.1.53";
        description = "Machop iPhone";
      };

      imac-machop = mkOption {
        type = str;
        default = "192.168.1.52";
        description = "iMac Machop";
      };

      # Network infrastructure
      router = mkOption {
        type = str;
        default = "192.168.1.1";
        description = "Primary router/gateway";
      };

      # IoT and smart home devices
      ring-doorbell = mkOption {
        type = str;
        default = "192.168.1.49";
        description = "Ring doorbell camera";
      };

      # Additional devices from DHCP assignments
      # (These appear in zues DHCP configuration)
      device-150 = mkOption {
        type = str;
        default = "192.168.1.150";
        description = "Network device .150";
      };

      device-152 = mkOption {
        type = str;
        default = "192.168.1.152";
        description = "Network device .152";
      };

      device-18 = mkOption {
        type = str;
        default = "192.168.1.18";
        description = "Network device .18";
      };

      device-19 = mkOption {
        type = str;
        default = "192.168.1.19";
        description = "Network device .19";
      };

      device-199 = mkOption {
        type = str;
        default = "192.168.1.199";
        description = "Network device .199";
      };

      device-200 = mkOption {
        type = str;
        default = "192.168.1.200";
        description = "Network device .200";
      };

      device-230 = mkOption {
        type = str;
        default = "192.168.1.230";
        description = "Network device .230";
      };

      device-254 = mkOption {
        type = str;
        default = "192.168.1.254";
        description = "Network device .254";
      };

      device-56 = mkOption {
        type = str;
        default = "192.168.1.56";
        description = "Network device .56";
      };

      device-60 = mkOption {
        type = str;
        default = "192.168.1.60";
        description = "Network device .60";
      };

      device-98 = mkOption {
        type = str;
        default = "192.168.1.98";
        description = "Network device .98";
      };
    };

    # DNS settings
    dns = {
      primary = mkOption {
        type = str;
        default = config.modules.network.hosts.zues;
        description = "Primary DNS server (usually zues)";
      };

      fallback = mkOption {
        type = str;
        default = "1.1.1.1";
        description = "Fallback DNS server";
      };
    };
  };
}
