{
  lib,
  config,
  ...
}: let
  inherit (lib) concatMapStringsSep mkIf mkOption;
  inherit (lib.types) ints listOf str;
  cfg = config.modules.nfs;
  lanSubnet = "192.168.1.0/24";
  nfsPorts = [
    111
    2049
    4000
    4001
    4002
  ];
in {
  options.modules.nfs = {
    exportPath = mkOption {
      type = str;
      default = "";
      description = "Path to export via NFS";
    };

    allowedHosts = mkOption {
      type = listOf str;
      default = [lanSubnet];
      description = "IP or CIDR allowed to mount this NFS export. Defaults to entire LAN subnet.";
    };

    firewallInterfaces = mkOption {
      type = listOf str;
      default = ["br0" "tailscale0"];
      description = "Interfaces on which NFS/RPC ports are opened.";
    };

    anonUid = mkOption {
      type = ints.unsigned;
      default = 1000;
      description = "UID used for all_squash NFS clients.";
    };

    anonGid = mkOption {
      type = ints.unsigned;
      default = 100;
      description = "GID used for all_squash NFS clients.";
    };
  };

  config = mkIf (cfg.exportPath != "") {
    services = {
      gvfs.enable = true;
      rpcbind.enable = true;
      nfs.server = {
        enable = true;

        lockdPort = 4001;
        mountdPort = 4002;
        statdPort = 4000;
        exports =
          concatMapStringsSep "\n" (
            host: "${cfg.exportPath} ${host}(rw,sync,no_subtree_check,insecure,all_squash,anonuid=${toString cfg.anonUid},anongid=${toString cfg.anonGid})"
          )
          cfg.allowedHosts;
      };
    };

    networking.firewall.interfaces = lib.genAttrs cfg.firewallInterfaces (_: {
      allowedTCPPorts = nfsPorts;
      allowedUDPPorts = nfsPorts;
    });
  };
}
