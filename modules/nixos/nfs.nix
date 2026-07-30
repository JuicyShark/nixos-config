{
  lib,
  config,
  ...
}: let
  inherit (lib) concatMapStringsSep mkIf mkOption;
  inherit (lib.types) ints listOf str;
  cfg = config.modules.nfs;
  lanSubnet = "192.168.1.0/24";
  nfsPort = 2049;
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
      nfs.settings.nfsd = {
        vers3 = false;
        vers4 = true;
        # macOS's `nfsvers=4` defaults to minor version 0, whereas Linux
        # clients generally negotiate the newest minor version. Keep every
        # NFSv4 minor version explicitly available so Darwin mounts remain
        # compatible across client and kernel upgrades.
        "vers4.0" = true;
        "vers4.1" = true;
        "vers4.2" = true;
      };
      nfs.server = {
        enable = true;
        exports =
          concatMapStringsSep "\n" (
            host: "${cfg.exportPath} ${host}(rw,sync,no_subtree_check,insecure,all_squash,anonuid=${toString cfg.anonUid},anongid=${toString cfg.anonGid})"
          )
          cfg.allowedHosts;
      };
    };

    networking.firewall.interfaces = lib.genAttrs cfg.firewallInterfaces (_: {
      allowedTCPPorts = [nfsPort];
    });

    systemd.services.nfs-server.unitConfig.RequiresMountsFor = [cfg.exportPath];
  };
}
