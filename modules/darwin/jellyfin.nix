{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) bool ints listOf package path str;

  cfg = config.modules.jellyfin;
  loginUser = config.modules.profile.username;
  loginHome = config.users.users.${loginUser}.home;

  jellyfinProgram = lib.getExe cfg.package;
  jellyfinBinary = "${cfg.package}/lib/jellyfin/jellyfin";
  launchdLog = "${cfg.logDir}/launchd.log";
  ownershipMarker = "${cfg.dataDir}/.nix-darwin-owner-${cfg.user}";
  usesDedicatedUser = cfg.user != loginUser;

  startJellyfin = pkgs.writeShellScript "start-jellyfin" ''
    set -eu

    # Touching the canonical Nixflix media roots primes macOS autofs mounts
    # before Jellyfin scans its persisted libraries.
    ${lib.concatMapStringsSep "\n" (mediaDir: ''
        if ! /usr/bin/stat ${lib.escapeShellArg mediaDir} >/dev/null 2>&1; then
          echo "Jellyfin media directory is unavailable: ${mediaDir}" >&2
          exit 1
        fi
      '')
      cfg.mediaDirectories}

    exec ${lib.escapeShellArg jellyfinProgram} \
      --datadir ${lib.escapeShellArg cfg.dataDir} \
      --configdir ${lib.escapeShellArg cfg.configDir} \
      --cachedir ${lib.escapeShellArg cfg.cacheDir} \
      --logdir ${lib.escapeShellArg cfg.logDir}
  '';
in {
  options.modules.jellyfin = {
    enable = mkEnableOption "Jellyfin media server on Darwin";

    package = mkOption {
      type = package;
      default = pkgs.jellyfin;
      defaultText = lib.literalExpression "pkgs.jellyfin";
      description = "Jellyfin package to run.";
    };

    user = mkOption {
      type = str;
      default = "jellyfin";
      description = "Dedicated account used by the Jellyfin daemon.";
    };

    uid = mkOption {
      type = ints.positive;
      default = 504;
      description = "Darwin UID reserved for the Jellyfin account.";
    };

    group = mkOption {
      type = str;
      default = "media";
      description = "Shared group used to access the Nixflix media library.";
    };

    gid = mkOption {
      type = ints.positive;
      default = 2000;
      description = "Darwin GID matching the NFS media group.";
    };

    homeDir = mkOption {
      type = path;
      default = "/var/jellyfin";
      description = "Home directory exposed to the Jellyfin process.";
    };

    dataDir = mkOption {
      type = path;
      default = "/var/lib/jellyfin";
      description = "Persistent Jellyfin state directory.";
    };

    configDir = mkOption {
      type = path;
      default = "${cfg.dataDir}/config";
      defaultText = lib.literalExpression ''"''${config.modules.jellyfin.dataDir}/config"'';
      description = "Jellyfin configuration directory.";
    };

    cacheDir = mkOption {
      type = path;
      default = "/var/cache/jellyfin";
      description = "Jellyfin cache directory.";
    };

    logDir = mkOption {
      type = path;
      default = "${cfg.dataDir}/log";
      defaultText = lib.literalExpression ''"''${config.modules.jellyfin.dataDir}/log"'';
      description = "Jellyfin application and launchd log directory.";
    };

    mediaDirectories = mkOption {
      type = listOf path;
      default = ["/mnt/chonk/media"];
      description = "Canonical Nixflix media roots that must be available before Jellyfin starts.";
    };

    allowLegacyUserMediaPath = mkOption {
      type = bool;
      default = true;
      description = ''
        Grant Jellyfin search access to the login user's home. This preserves
        existing libraries stored through paths such as ~/chonk/media while
        the canonical media root remains /mnt/chonk/media.
      '';
    };

    openFirewall = mkOption {
      type = bool;
      default = true;
      description = "Register Jellyfin with the macOS application firewall.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.mediaDirectories != [];
        message = "modules.jellyfin.mediaDirectories must contain at least one media root.";
      }
    ];

    users = {
      knownGroups = [cfg.group];
      knownUsers = lib.optionals usesDedicatedUser [cfg.user];

      groups.${cfg.group} = {
        inherit (cfg) gid;
        description = "Shared media services";
        members = lib.optionals usesDedicatedUser [cfg.user] ++ [loginUser];
      };

      users = lib.optionalAttrs usesDedicatedUser {
        ${cfg.user} = {
          inherit (cfg) uid;
          inherit (cfg) gid;
          description = "Jellyfin media server";
          home = cfg.homeDir;
          createHome = false;
          isHidden = true;
        };
      };
    };

    # `etc` runs after nix-darwin creates managed users and before launchd
    # reloads the daemon.
    system.activationScripts.etc.text = lib.mkAfter ''
      echo "preparing Jellyfin service state..." >&2
      /usr/bin/install -d -o ${lib.escapeShellArg cfg.user} -g ${lib.escapeShellArg cfg.group} -m 0750 ${lib.escapeShellArg cfg.homeDir}
      /usr/bin/install -d -o ${lib.escapeShellArg cfg.user} -g ${lib.escapeShellArg cfg.group} -m 0750 ${lib.escapeShellArg cfg.dataDir}
      /usr/bin/install -d -o ${lib.escapeShellArg cfg.user} -g ${lib.escapeShellArg cfg.group} -m 0750 ${lib.escapeShellArg cfg.configDir}
      /usr/bin/install -d -o ${lib.escapeShellArg cfg.user} -g ${lib.escapeShellArg cfg.group} -m 0750 ${lib.escapeShellArg cfg.cacheDir}
      /usr/bin/install -d -o ${lib.escapeShellArg cfg.user} -g ${lib.escapeShellArg cfg.group} -m 0750 ${lib.escapeShellArg cfg.logDir}
      /usr/bin/install -d -o ${lib.escapeShellArg cfg.user} -g ${lib.escapeShellArg cfg.group} -m 0750 ${lib.escapeShellArg cfg.dataDir}/data

      # Existing state was historically written by the login user. Migrate it
      # once, without recursively chowning a large cache on every activation.
      if [ ! -e ${lib.escapeShellArg ownershipMarker} ]; then
        echo "migrating existing Jellyfin state to ${cfg.user}:${cfg.group}..." >&2
        /usr/sbin/chown -R ${lib.escapeShellArg cfg.user}:${lib.escapeShellArg cfg.group} ${lib.escapeShellArg cfg.homeDir} ${lib.escapeShellArg cfg.dataDir} ${lib.escapeShellArg cfg.cacheDir}
        /usr/bin/touch ${lib.escapeShellArg ownershipMarker}
        /usr/sbin/chown ${lib.escapeShellArg cfg.user}:${lib.escapeShellArg cfg.group} ${lib.escapeShellArg ownershipMarker}
      fi

      /usr/bin/touch ${lib.escapeShellArg launchdLog}
      /usr/sbin/chown ${lib.escapeShellArg cfg.user}:${lib.escapeShellArg cfg.group} ${lib.escapeShellArg launchdLog}
      /bin/chmod 0640 ${lib.escapeShellArg launchdLog}

      ${lib.optionalString (cfg.allowLegacyUserMediaPath && usesDedicatedUser) ''
        # Existing Jellyfin libraries use ~/chonk, a symlink to /mnt/chonk.
        # Grant traversal only; the service does not receive access to other
        # files in the login user's home.
        /bin/chmod -a "${cfg.user} allow search" ${lib.escapeShellArg loginHome} 2>/dev/null || true
        /bin/chmod +a "${cfg.user} allow search" ${lib.escapeShellArg loginHome}
      ''}

      ${lib.optionalString cfg.openFirewall ''
        echo "allowing Jellyfin through the macOS application firewall..." >&2
        reconcile_firewall_app() {
          current_app="$1"
          app_suffix="$2"

          /usr/libexec/ApplicationFirewall/socketfilterfw --listapps |
            /usr/bin/awk -F ' : ' '/^[[:space:]]*[0-9]+ : / { print $2 }' |
            while IFS= read -r registered_app; do
              case "$registered_app" in
                /nix/store/*"$app_suffix")
                  if [ "$registered_app" != "$current_app" ]; then
                    /usr/libexec/ApplicationFirewall/socketfilterfw --remove "$registered_app" || true
                  fi
                  ;;
              esac
            done

          /usr/libexec/ApplicationFirewall/socketfilterfw --add "$current_app" || true
          /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp "$current_app"
        }

        reconcile_firewall_app ${lib.escapeShellArg jellyfinProgram} /bin/jellyfin
        reconcile_firewall_app ${lib.escapeShellArg jellyfinBinary} /lib/jellyfin/jellyfin
      ''}
    '';

    launchd.daemons.jellyfin = {
      serviceConfig = {
        # Direct launchd execution of unsigned Nix-store paths is denied by
        # macOS. Run the generated script through the system-signed shell.
        ProgramArguments = [
          "/bin/sh"
          "${startJellyfin}"
        ];
        WorkingDirectory = cfg.dataDir;
        RunAtLoad = true;
        KeepAlive.SuccessfulExit = false;
        UserName = cfg.user;
        GroupName = cfg.group;
        EnvironmentVariables.HOME = cfg.homeDir;
        StandardOutPath = launchdLog;
        StandardErrorPath = launchdLog;
        ProcessType = "Background";
        ThrottleInterval = 30;
        ExitTimeOut = 15;
        Umask = 7;
      };
    };
  };
}
