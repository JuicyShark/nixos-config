{
  nix-config,
  system,
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption mkDefault;
  inherit (lib.types) str;
  inherit (nix-config.lib.${system}.roles) mkHasRole;

  hasRole = mkHasRole config;
  cfg = config.modules.nfs;
in
{
  options.modules.nfs = {
    exportPath = mkOption {
      type = str;
      default = "";
      description = "Path to export via NFS";
    };
    exportSubnet = mkOption {
      type = str;
      default = "192.168.1.0/24";
      description = "Subnet to allow NFS access";
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
        exports = "
          ${cfg.exportPath} ${cfg.exportSubnet}(rw,async,no_subtree_check,all_squash,anonuid=1000,anongid=100,insecure)
          ";
      };
    };

    networking.firewall = {
      allowedUDPPorts = [
        111
        2049
        4000
        4001
        4002
      ];
      allowedTCPPorts = [
        111
        2049
        4000
        4001
        4002
      ];
    };
  };
}
