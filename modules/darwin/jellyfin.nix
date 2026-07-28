{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.jellyfin;
  username = config.modules.profile.username;
  userHome = config.users.users.${username}.home;
  userId = 504;
  home = "/var/jellyfin";

  dataDir = "/var/lib/jellyfin";
  configDir = "${dataDir}/config";
  cacheDir = "/var/cache/jellyfin";
  logDir = "${dataDir}/log";
  launchdLog = "${logDir}/launchd.log";
  jellyfin = lib.getExe pkgs.jellyfin;
  jellyfinWorkDir = "${pkgs.jellyfin}/lib/jellyfin";
in {
  options.modules.jellyfin.enable = lib.mkEnableOption "Jellyfin media server on Darwin";

  config = lib.mkIf cfg.enable {
    users = {
      knownGroups = ["media"];
      knownUsers = ["jellyfin"];

      groups.media = {
        gid = 2000;
        description = "Shared media services";
        members = ["jellyfin" username];
      };

      users.jellyfin = {
        uid = userId;
        gid = 2000;
        description = "Jellyfin media server";
        isHidden = true;
        inherit home;
        createHome = false;
      };
    };

    system.activationScripts.extraActivation.text = lib.mkAfter ''
      echo "allowing Jellyfin through the macOS application firewall..." >&2
      /usr/libexec/ApplicationFirewall/socketfilterfw --add ${lib.escapeShellArg jellyfin} || true
      /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp ${lib.escapeShellArg jellyfin} || true
    '';

    # `extraActivation` runs before nix-darwin creates managed users.
    # `etc` runs after groups/users and before launchd reloads the daemon.
    system.activationScripts.etc.text = lib.mkAfter ''
      echo "preparing Jellyfin server directories..." >&2
      /usr/bin/install -d -o jellyfin -g media -m 0750 ${lib.escapeShellArg home}
      /usr/bin/install -d -o jellyfin -g media -m 0775 ${lib.escapeShellArg dataDir}
      /usr/bin/install -d -o jellyfin -g media -m 0775 ${lib.escapeShellArg configDir}
      /usr/bin/install -d -o jellyfin -g media -m 0775 ${lib.escapeShellArg cacheDir}
      /usr/bin/install -d -o jellyfin -g media -m 0775 ${lib.escapeShellArg logDir}
      /usr/sbin/chown -R jellyfin:media ${lib.escapeShellArg home} ${lib.escapeShellArg dataDir} ${lib.escapeShellArg cacheDir}
      /bin/chmod -R u+rwX,g+rwX ${lib.escapeShellArg home} ${lib.escapeShellArg dataDir} ${lib.escapeShellArg cacheDir}
      /bin/chmod -a "jellyfin allow search" ${lib.escapeShellArg userHome} 2>/dev/null || true
      /bin/chmod +a "jellyfin allow search" ${lib.escapeShellArg userHome}
      /usr/bin/touch ${lib.escapeShellArg launchdLog}
      /usr/sbin/chown jellyfin:media ${lib.escapeShellArg launchdLog}
      /bin/chmod 0644 ${lib.escapeShellArg launchdLog}
    '';

    launchd.daemons.jellyfin = {
      serviceConfig = {
        ProgramArguments = [
          jellyfin
          "--datadir"
          dataDir
          "--configdir"
          configDir
          "--cachedir"
          cacheDir
          "--logdir"
          logDir
        ];
        WorkingDirectory = jellyfinWorkDir;
        # System LaunchDaemons start at boot, before any user logs in.
        RunAtLoad = true;
        # KeepAlive makes launchd bring Jellyfin back after crashes or exits.
        KeepAlive = true;
        # Run as the login user so autofs/NFS media mounts are visible.
        UserName = username;
        GroupName = "media";
        EnvironmentVariables.HOME = home;
        StandardOutPath = launchdLog;
        StandardErrorPath = launchdLog;
        # Avoid tight restart loops if Jellyfin fails early during boot.
        ThrottleInterval = 30;
      };
    };
  };
}
