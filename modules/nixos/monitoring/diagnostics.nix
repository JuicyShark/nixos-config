{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.monitoring.diagnostics;
  inherit (config.modules.profile) username;
  stateDirectory = "homelab-diagnostics";
  statePath = "/var/lib/${stateDirectory}";
  runtimeDirectory = "homelab-diagnostics";
  diagnostics = pkgs.writeShellApplication {
    name = "homelab-diagnostics";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      curl
      gawk
      gnugrep
      gnused
      herdr
      jq
      openssh
      systemd
      util-linux
    ];
    text = builtins.readFile ./homelab-diagnostics.sh;
  };
  commonEnvironment = {
    DIAGNOSTICS_STATE_DIR = statePath;
    DIAGNOSTICS_SSH_USER = cfg.sshUser;
    DIAGNOSTICS_SSH_IDENTITY = config.age.secrets.homelab-key.path;
    DIAGNOSTICS_SMTP_EMAIL = cfg.smtpEmail;
    DIAGNOSTICS_SMTP_ENVIRONMENT = config.age.secrets."homelab-diagnostics-smtp.env".path;
    DIAGNOSTICS_HERDR_SESSION = cfg.herdrSession;
    DIAGNOSTICS_HERDR_AGENT = cfg.herdrAgent;
    DIAGNOSTICS_WORKSPACE = cfg.workspace;
    DIAGNOSTICS_LOCAL_MODEL_ENDPOINT = cfg.localModelEndpoint;
    DIAGNOSTICS_LOCAL_MODEL = cfg.localModel;
    DIAGNOSTICS_PROMETHEUS_URL = cfg.prometheusUrl;
    HOME = config.users.users.${username}.home;
  };
  commonService = {
    after = [
      "agenix.service"
      "network-online.target"
      "herdr-homelab.service"
    ];
    wants = [
      "network-online.target"
      "herdr-homelab.service"
    ];
    environment = commonEnvironment;
    path = [pkgs.codex];
    serviceConfig = {
      Type = "oneshot";
      User = username;
      Group = config.users.users.${username}.group;
      StateDirectory = stateDirectory;
      StateDirectoryMode = "0700";
      RuntimeDirectory = runtimeDirectory;
      RuntimeDirectoryMode = "0700";
      UMask = "0077";
      TimeoutStartSec = "7m";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ReadWritePaths = [
        statePath
        config.users.users.${username}.home
      ];
    };
  };
in {
  options.modules.monitoring.diagnostics = {
    enable = lib.mkEnableOption "read-only Herdr-assisted homelab diagnostics";

    sshUser = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Unprivileged SSH user used for read-only host diagnostics.";
    };

    smtpEmail = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Address used to send and receive independent diagnostic email.";
    };

    workspace = lib.mkOption {
      type = lib.types.str;
      default =
        if config.modules.profile.flakePath == null
        then ""
        else config.modules.profile.flakePath;
      defaultText = lib.literalExpression ''config.modules.profile.flakePath or ""'';
      description = "Repository context supplied to the Herdr-managed diagnostic agent.";
    };

    herdrSession = lib.mkOption {
      type = lib.types.str;
      default = "homelab-watch";
      description = "Named Herdr session isolated from interactive work.";
    };

    herdrAgent = lib.mkOption {
      type = lib.types.str;
      default = "homelab-triage";
      description = "Herdr agent name used for contextual diagnostic review.";
    };

    localModelEndpoint = lib.mkOption {
      type = lib.types.str;
      default = config.modules.localModels.endpoint;
      defaultText = lib.literalExpression "config.modules.localModels.endpoint";
      description = "Trusted Ollama endpoint used for routine first-pass triage.";
    };

    localModel = lib.mkOption {
      type = lib.types.str;
      default = config.modules.localModels.defaultModel;
      defaultText = lib.literalExpression "config.modules.localModels.defaultModel";
      description = "Small local model used for routine snapshot classification.";
    };

    prometheusUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://prometheus.home.arpa";
      description = "Prometheus API polled for active deterministic findings.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.smtpEmail != "";
        message = "modules.monitoring.diagnostics.smtpEmail must be set";
      }
      {
        assertion = cfg.workspace != "";
        message = "modules.monitoring.diagnostics.workspace must be set";
      }
      {
        assertion = config.modules.localModels.enable;
        message = "modules.monitoring.diagnostics requires modules.localModels.enable";
      }
      {
        assertion = cfg.localModelEndpoint != "" && cfg.localModel != "" && cfg.prometheusUrl != "";
        message = "modules.monitoring.diagnostics model and Prometheus endpoints must be set";
      }
    ];

    age.secrets."homelab-diagnostics-smtp.env" = {
      file = ../../../secrets/vaultwarden.env.age;
      owner = username;
      group = config.users.users.${username}.group;
      mode = "0400";
    };
    age.secrets.homelab-key = {
      file = ../../../secrets/homelab-key.age;
      owner = username;
      group = config.users.users.${username}.group;
      mode = "0400";
    };

    environment.systemPackages = [
      diagnostics
      pkgs.herdr
    ];

    systemd.services = {
      herdr-homelab = {
        description = "Headless Herdr server for homelab diagnostics";
        wantedBy = ["multi-user.target"];
        after = ["network-online.target"];
        wants = ["network-online.target"];
        environment.HOME = config.users.users.${username}.home;
        path = with pkgs; [
          bash
          codex
          coreutils
          jq
        ];
        serviceConfig = {
          Type = "simple";
          User = username;
          Group = config.users.users.${username}.group;
          ExecStart = "${lib.getExe pkgs.herdr} --session ${cfg.herdrSession} server";
          Restart = "on-failure";
          RestartSec = 5;
          UMask = "0077";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ReadWritePaths = [config.users.users.${username}.home];
        };
      };

      homelab-diagnostics =
        commonService
        // {
          description = "Collect diagnostics and send at most one bad finding daily";
          serviceConfig =
            commonService.serviceConfig
            // {
              ExecStart = "${lib.getExe diagnostics} scan";
            };
        };

      homelab-diagnostics-digest =
        commonService
        // {
          description = "Send daily contextual homelab diagnostic digest";
          serviceConfig =
            commonService.serviceConfig
            // {
              ExecStart = "${lib.getExe diagnostics} digest";
            };
        };
    };

    systemd.timers = {
      homelab-diagnostics = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "10m";
          OnUnitActiveSec = "15m";
          RandomizedDelaySec = "2m";
          Persistent = true;
        };
      };

      homelab-diagnostics-digest = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "*-*-* 08:00:00";
          RandomizedDelaySec = "10m";
          Persistent = true;
        };
      };
    };
  };
}
