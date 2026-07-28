{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) str;
  cfg = config.modules.gitServer;
in {
  options.modules.gitServer = {
    enable = mkEnableOption "private SSH Git hosting via Gitolite";

    dataDir = mkOption {
      type = str;
      default = "/srv/smol/git";
      description = "Gitolite home directory and repository storage path.";
    };

    adminPubkey = mkOption {
      type = str;
      default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILUlQ0gc5NIpsO3qPU7NR9NF8DobGXlhlmVzP944USPC juicy@leo";
      description = "Initial Gitolite admin SSH public key.";
    };

    user = mkOption {
      type = str;
      default = "git";
      description = "SSH user for Git hosting.";
    };

    group = mkOption {
      type = str;
      default = "git";
      description = "Primary group for Git hosting.";
    };
  };

  config = mkIf cfg.enable {
    services.gitolite = {
      enable = true;
      inherit (cfg) dataDir;
      inherit (cfg) adminPubkey;
      inherit (cfg) user;
      inherit (cfg) group;
      extraGitoliteRc = ''
        $RC{UMASK} = 0027;
        $RC{SITE_INFO} = 'leo private git';
      '';
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.gitolite-init.unitConfig.RequiresMountsFor = [cfg.dataDir];
  };
}
