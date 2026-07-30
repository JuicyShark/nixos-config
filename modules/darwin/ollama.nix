{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) bool ints listOf package path port str;

  cfg = config.modules.ollama;
  user = config.modules.profile.username;
  ollamaProgram = lib.getExe cfg.package;
  apiEndpoint = "http://${cfg.listenAddress}:${toString cfg.port}";
  launchdLog = "${cfg.stateDir}/ollama.log";

  bootstrapModels = pkgs.writeShellApplication {
    name = "local-models-bootstrap";
    runtimeInputs = [cfg.package];
    text = ''
      export OLLAMA_HOST=${lib.escapeShellArg apiEndpoint}

      for model in ${lib.escapeShellArgs cfg.recommendedModels}; do
        echo "pulling $model..." >&2
        ollama pull "$model"
      done

      ollama list
    '';
  };

  startOllama = pkgs.writeShellScript "start-ollama" ''
    set -eu
    exec ${lib.escapeShellArg ollamaProgram} serve
  '';
in {
  options.modules.ollama = {
    enable = mkEnableOption "Ollama model server on Darwin";

    package = mkOption {
      type = package;
      default = pkgs.ollama;
      defaultText = lib.literalExpression "pkgs.ollama";
      description = "Ollama package to serve.";
    };

    listenAddress = mkOption {
      type = str;
      default = "127.0.0.1";
      description = ''
        Address on which Ollama listens. Ollama does not authenticate API
        requests, so this should be a trusted interface rather than 0.0.0.0.
      '';
    };

    port = mkOption {
      type = port;
      default = 11434;
      description = "Ollama API port.";
    };

    stateDir = mkOption {
      type = path;
      default = "/var/lib/ollama";
      description = "Persistent model and log directory.";
    };

    contextLength = mkOption {
      type = ints.positive;
      default = 16384;
      description = "Maximum context allocated per request.";
    };

    maxLoadedModels = mkOption {
      type = ints.positive;
      default = 1;
      description = "Maximum number of models retained in unified memory.";
    };

    parallelRequests = mkOption {
      type = ints.positive;
      default = 1;
      description = "Maximum parallel requests per loaded model.";
    };

    recommendedModels = mkOption {
      type = listOf str;
      default = [
        "qwen3.5:9b"
        "embeddinggemma"
      ];
      description = "Models fetched by local-models-bootstrap.";
    };

    openFirewall = mkOption {
      type = bool;
      default = true;
      description = "Register Ollama with the macOS application firewall.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.listenAddress != "0.0.0.0" && cfg.listenAddress != "::";
        message = "Ollama has no API authentication; bind it to an explicit trusted address.";
      }
      {
        assertion = cfg.recommendedModels != [];
        message = "modules.ollama.recommendedModels must contain at least one model.";
      }
    ];

    environment.systemPackages = [
      cfg.package
      bootstrapModels
    ];

    system.activationScripts.etc.text = lib.mkAfter ''
      echo "preparing Ollama service state..." >&2
      /usr/bin/install -d -o ${lib.escapeShellArg user} -g staff -m 0750 ${lib.escapeShellArg cfg.stateDir}
      /usr/bin/install -d -o ${lib.escapeShellArg user} -g staff -m 0750 ${lib.escapeShellArg "${cfg.stateDir}/models"}
      /usr/bin/touch ${lib.escapeShellArg launchdLog}
      /usr/sbin/chown ${lib.escapeShellArg user}:staff ${lib.escapeShellArg launchdLog}
      /bin/chmod 0640 ${lib.escapeShellArg launchdLog}

      ${lib.optionalString cfg.openFirewall ''
        echo "allowing Ollama through the macOS application firewall..." >&2
        current_app=${lib.escapeShellArg ollamaProgram}

        /usr/libexec/ApplicationFirewall/socketfilterfw --listapps |
          /usr/bin/awk -F ' : ' '/^[[:space:]]*[0-9]+ : / { print $2 }' |
          while IFS= read -r registered_app; do
            case "$registered_app" in
              /nix/store/*/bin/ollama)
                if [ "$registered_app" != "$current_app" ]; then
                  /usr/libexec/ApplicationFirewall/socketfilterfw --remove "$registered_app" || true
                fi
                ;;
            esac
          done

        /usr/libexec/ApplicationFirewall/socketfilterfw --add "$current_app" || true
        /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp "$current_app"
      ''}
    '';

    launchd.daemons.ollama = {
      serviceConfig = {
        ProgramArguments = [
          "/bin/sh"
          "${startOllama}"
        ];
        WorkingDirectory = cfg.stateDir;
        RunAtLoad = true;
        KeepAlive.SuccessfulExit = false;
        UserName = user;
        GroupName = "staff";
        EnvironmentVariables = {
          HOME = config.users.users.${user}.home;
          OLLAMA_HOST = "${cfg.listenAddress}:${toString cfg.port}";
          OLLAMA_MODELS = "${cfg.stateDir}/models";
          OLLAMA_CONTEXT_LENGTH = toString cfg.contextLength;
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_KV_CACHE_TYPE = "q8_0";
          OLLAMA_MAX_LOADED_MODELS = toString cfg.maxLoadedModels;
          OLLAMA_NUM_PARALLEL = toString cfg.parallelRequests;
        };
        StandardOutPath = launchdLog;
        StandardErrorPath = launchdLog;
        ProcessType = "Interactive";
        ThrottleInterval = 10;
        ExitTimeOut = 30;
        Umask = 7;
      };
    };
  };
}
