{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.localModels;

  localChat = pkgs.writeShellApplication {
    name = "local-chat";
    runtimeInputs = [cfg.package];
    text = ''
      model="''${LOCAL_LLM_MODEL:-${cfg.defaultModel}}"

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

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ollama;
      defaultText = lib.literalExpression "pkgs.ollama";
      description = "Ollama package that provides the remote client.";
    };

    endpoint = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:11434";
      description = "Ollama API endpoint used by command-line clients.";
    };

    defaultModel = lib.mkOption {
      type = lib.types.str;
      default = "qwen3.5:9b";
      description = "Model used by local-chat unless --model is supplied.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [
        cfg.package
        localChat
      ];
      variables = {
        OLLAMA_HOST = cfg.endpoint;
        LOCAL_LLM_MODEL = cfg.defaultModel;
      };
    };
  };
}
