{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) str;
  cfg = config.modules.homelab.mediaVote;
  ports = config.modules.ports;

  source = pkgs.stdenvNoCC.mkDerivation {
    pname = "media-vote";
    version = "0.1.0";
    src = ../../../packages/media-vote;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      install -Dm644 app.py "$out/share/media-vote/app.py"
      cp -R static templates "$out/share/media-vote/"
      runHook postInstall
    '';
  };

  python = pkgs.python3.withPackages (pythonPackages:
    with pythonPackages; [
      flask
      gunicorn
    ]);

  commonServiceConfig = {
    User = "media-vote";
    Group = "media-vote";
    StateDirectory = "media-vote";
    StateDirectoryMode = "0700";
    WorkingDirectory = "${source}/share/media-vote";
    LoadCredential = [
      "jellyfin-api:${config.age.secrets.jellyfin-api.path}"
    ];
    UMask = "0077";

    CapabilityBoundingSet = "";
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateTmp = true;
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectSystem = "strict";
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
    ];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = [
      "@system-service"
      "~@privileged"
      "~@resources"
    ];
  };

  commonEnvironment = {
    MEDIA_VOTE_ADMIN_USERNAME = cfg.adminUsername;
    MEDIA_VOTE_DATABASE = "/var/lib/media-vote/votes.sqlite";
    MEDIA_VOTE_JELLYFIN_API_KEY_FILE = "%d/jellyfin-api";
    MEDIA_VOTE_JELLYFIN_URL = cfg.jellyfinUrl;
    MEDIA_VOTE_SYNC_LOCK = "/var/lib/media-vote/sync.lock";
  };
in {
  options.modules.homelab.mediaVote = {
    enable = mkEnableOption "Jellyfin-backed media voting site";

    jellyfinUrl = mkOption {
      type = str;
      default = "http://${config.modules.homelab.jellyfin.host}:${toString ports.jellyfin}";
      description = "Jellyfin base URL used for login and library metadata.";
    };

    adminUsername = mkOption {
      type = str;
      default = config.modules.homelab.jellyfin.adminUsername;
      description = "Jellyfin username allowed to access admin voting views.";
    };
  };

  config = mkIf cfg.enable {
    users.groups.media-vote = {};
    users.users.media-vote = {
      isSystemUser = true;
      group = "media-vote";
    };

    systemd = {
      services.media-vote = {
        description = "Jellyfin media voting companion";
        wantedBy = ["multi-user.target"];
        after = ["network-online.target"];
        wants = ["network-online.target"];

        environment = commonEnvironment;

        serviceConfig =
          commonServiceConfig
          // {
            Type = "simple";
            ExecStart = ''
              ${python}/bin/gunicorn \
                --bind 127.0.0.1:${toString ports.mediaVote} \
                --workers 1 \
                --threads 8 \
                --timeout 120 \
                --access-logfile - \
                app:app
            '';
            Restart = "on-failure";
            RestartSec = "3s";
          };
      };

      services.media-vote-sync = {
        description = "Synchronize the Media Vote Jellyfin catalog";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        environment = commonEnvironment;
        serviceConfig =
          commonServiceConfig
          // {
            Type = "oneshot";
            ExecStart = "${python}/bin/python3 ${source}/share/media-vote/app.py sync";
          };
      };

      timers.media-vote-sync = {
        description = "Periodically synchronize the Media Vote catalog";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "2m";
          OnUnitActiveSec = "6h";
          RandomizedDelaySec = "5m";
          Persistent = true;
          Unit = "media-vote-sync.service";
        };
      };
    };

    services.nginx.virtualHosts."media-vote.home.arpa".locations."/" = {
      proxyPass = "http://127.0.0.1:${toString ports.mediaVote}";
      proxyWebsockets = false;
    };
  };
}
