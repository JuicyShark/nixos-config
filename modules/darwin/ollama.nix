{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption;
  inherit (lib.types) str;

  cfg = config.modules.ollama;
  user = config.modules.profile.username;
  package = pkgs.ollama;
  stateDir = "/var/lib/ollama";
  ollamaProgram = lib.getExe package;
  apiEndpoint = "http://${cfg.listenAddress}:11434";
  launchdLog = "${stateDir}/ollama.log";

  bootstrapModels = pkgs.writeShellApplication {
    name = "local-models-bootstrap";
    runtimeInputs = [package];
    text = ''
      export OLLAMA_HOST=${lib.escapeShellArg apiEndpoint}

      for model in qwen3.5:9b embeddinggemma; do
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

    listenAddress = mkOption {
      type = str;
      default = "127.0.0.1";
      description = ''
        Address on which Ollama listens. Ollama does not authenticate API
        requests, so this should be a trusted interface rather than 0.0.0.0.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.listenAddress != "0.0.0.0" && cfg.listenAddress != "::";
        message = "Ollama has no API authentication; bind it to an explicit trusted address.";
      }
    ];

    environment.systemPackages = [
      package
      bootstrapModels
    ];

    system.activationScripts.etc.text = lib.mkAfter ''
      echo "preparing Ollama service state..." >&2
      /usr/bin/install -d -o ${lib.escapeShellArg user} -g staff -m 0750 ${stateDir}
      /usr/bin/install -d -o ${lib.escapeShellArg user} -g staff -m 0750 ${stateDir}/models
      /usr/bin/touch ${lib.escapeShellArg launchdLog}
      /usr/sbin/chown ${lib.escapeShellArg user}:staff ${lib.escapeShellArg launchdLog}
      /bin/chmod 0640 ${lib.escapeShellArg launchdLog}

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
    '';

    launchd.daemons.ollama = {
      serviceConfig = {
        ProgramArguments = [
          "/bin/sh"
          "${startOllama}"
        ];
        WorkingDirectory = stateDir;
        RunAtLoad = true;
        KeepAlive.SuccessfulExit = false;
        UserName = user;
        GroupName = "staff";
        EnvironmentVariables = {
          HOME = config.users.users.${user}.home;
          OLLAMA_HOST = "${cfg.listenAddress}:11434";
          OLLAMA_MODELS = "${stateDir}/models";
          OLLAMA_CONTEXT_LENGTH = "16384";
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_KV_CACHE_TYPE = "q8_0";
          OLLAMA_MAX_LOADED_MODELS = "1";
          OLLAMA_NUM_PARALLEL = "1";
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
