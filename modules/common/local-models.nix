{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.localModels;
  package = pkgs.ollama;

  localChat = pkgs.writeShellApplication {
    name = "local-chat";
    runtimeInputs = [package];
    text = ''
      model="''${LOCAL_LLM_MODEL:-}"
      if [ -z "$model" ]; then
        model=${lib.escapeShellArg cfg.model}
      fi

      if [ "''${1:-}" = "--model" ]; then
        if [ "$#" -lt 2 ]; then
          echo "usage: local-chat [--model MODEL] [PROMPT...]" >&2
          exit 2
        fi
        model="$2"
        shift 2
      fi

      exec ollama run "$model" "$@"
    '';
  };
in {
  options.modules.localModels = {
    enable = lib.mkEnableOption "an Ollama client for the shared local-model server";

    endpoint = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:11434";
      description = "Ollama API endpoint used by command-line clients.";
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "qwen3.5:9b";
      description = "Default Ollama model shared by local-chat and Pi.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [
        package
        localChat
      ];
      variables = {
        OLLAMA_HOST = cfg.endpoint;
        LOCAL_LLM_MODEL = cfg.model;
      };
    };
  };
}
