{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption mkEnableOption;
  inherit (lib.types) str;
  cfg = config.modules.shairport;
in {
  options.modules.shairport = {
    enable = mkEnableOption "AirPlay receiver via shairport-sync";
    name = mkOption {
      type = str;
      default = config.networking.hostName;
      description = "AirPlay receiver name advertised by shairport-sync.";
    };
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
    # shairport-sync itself runs as a user service (modules/home/shairport.nix)
    # so it can route through PipeWire. This NixOS module only provides the
    # supporting infrastructure: Avahi and firewall holes.
    services.avahi = {
      enable = true;
      ipv6 = false;
      openFirewall = false;
      allowInterfaces = [cfg.interface];
      publish.enable = true;
      publish.userServices = true;
    };

    networking.firewall.interfaces.${cfg.interface} = {
      allowedTCPPorts = [5000];
      allowedUDPPorts = [5353];
      allowedUDPPortRanges = [
        {
          from = 6001;
          to = 6010;
        }
      ];
    };
  };
}
