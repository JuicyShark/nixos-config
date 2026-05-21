# Network Configuration
#
# Centralizes host IPs, subnets, and DNS settings.
{
  lib,
  config,
  ...
}: let
  mkNetworkOption = default: description:
    lib.mkOption {
      type = lib.types.str;
      inherit default description;
    };
in {
  options.modules.network = {
    subnets = {
      lan = mkNetworkOption "192.168.1.0/24" "Home LAN subnet";
      tailscale = mkNetworkOption "100.64.0.0/10" "Tailscale CGNAT range";
      cloudflare1 = mkNetworkOption "172.64.0.0/13" "Cloudflare IP range 1";
      cloudflare2 = mkNetworkOption "131.0.72.0/22" "Cloudflare IP range 2";
    };

    hosts = {
      leo = mkNetworkOption "192.168.1.54" "Leo desktop (main workstation)";
      zues = mkNetworkOption "192.168.1.99" "Zues homelab server";
      fallarbor = mkNetworkOption "100.112.235.76" "Fallarbor VPS (Linode) - Tailscale IP for internal scraping";
      machop = mkNetworkOption "192.168.1.54" "Machop network alias for leo";
      machop-iphone = mkNetworkOption "192.168.1.53" "Machop iPhone";
      imac-machop = mkNetworkOption "192.168.1.52" "iMac Machop";
      router = mkNetworkOption "192.168.1.1" "Primary router/gateway";
      homeAssistant = mkNetworkOption "192.168.1.49" "Home Assistant instance";
      viridian = mkNetworkOption "192.168.1.150" "Viridian PC";
      viridian-monitor = mkNetworkOption "192.168.1.152" "Viridian monitor (smart display)";
      grow-light = mkNetworkOption "192.168.1.18" "Big grow light smart plug";
      smart-plug = mkNetworkOption "192.168.1.19" "Smart plug 2";
      evee-ps5 = mkNetworkOption "192.168.1.230" "Evee PS5";
      hermes = mkNetworkOption "192.168.1.56" "Hermes device";
      dante = mkNetworkOption "192.168.1.60" "Dante device";
      quagsire-laptop = mkNetworkOption "192.168.1.120" "Quagsire laptop";
    };

    dns = {
      primary = mkNetworkOption config.modules.network.hosts.zues "Primary DNS server";
      fallback = mkNetworkOption "1.1.1.1" "Fallback DNS server";
    };
  };
}
