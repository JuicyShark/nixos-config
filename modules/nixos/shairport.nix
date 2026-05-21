{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkOption mkEnableOption;
  inherit (lib.types) str;
  cfg = config.modules.shairport;
in {
  options.modules.shairport = {
    enable = mkEnableOption "AirPlay receiver via shairport-sync";
    interface = mkOption {
      type = str;
      default = "enp7s0";
      description = ''
        Network interface to restrict Avahi mDNS announcements to.
        Set to the physical NIC name to avoid conflicts with Steam/Vivaldi
        which bind to 224.0.0.251:5353 on all interfaces.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # nqptp: precision timing daemon required by AirPlay 2.
    # Must run as root — binds to privileged PTP ports 319/320.
    systemd.services.nqptp = {
      description = "Network Precision Time Protocol daemon for AirPlay 2";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${pkgs.nqptp}/bin/nqptp";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # shairport-sync itself runs as a user service (modules/home/shairport.nix)
    # so it can route through PipeWire. This NixOS module only provides the
    # supporting infrastructure: nqptp, avahi, and firewall holes.

    # Avahi for AirPlay discovery.
    # - ipv6 = false: prevents Apple devices preferring the ULA IPv6 address.
    # - allowInterfaces: restrict to the physical NIC only to avoid mDNS conflicts
    #   with Steam/Vivaldi which bind on all interfaces.
    services.avahi = {
      enable = true;
      ipv4 = true;
      ipv6 = false;
      allowInterfaces = [cfg.interface];
      publish.enable = true;
      publish.userServices = true;
    };

    # Firewall holes, restricted to the announce interface so nothing is
    # exposed on Tailscale / VPN / secondary NICs:
    #   - TCP 7000: RTSP (AirPlay)
    #   - TCP 32768-60999: Linux ephemeral range. AirPlay 2 opens event/timing
    #     callback ports on demand; shairport can't pin them, so the whole
    #     ephemeral range has to be reachable from the LAN.
    #   - UDP 319/320: nqptp PTP timing
    #   - UDP 6001-6010: RTP audio (narrowed via udp_port_base/range)
    networking.firewall.interfaces.${cfg.interface} = {
      allowedTCPPorts = [7000];
      allowedTCPPortRanges = [
        {
          from = 32768;
          to = 60999;
        }
      ];
      allowedUDPPorts = [
        319
        320
      ];
      allowedUDPPortRanges = [
        {
          from = 6001;
          to = 6010;
        }
      ];
    };
  };
}
