{
  osConfig,
  pkgs,
  lib,
  inputs,
  ...
}: let
  desktopEnabled = osConfig.modules.desktop.enable or false;
in {
  imports = [inputs.walker.homeManagerModules.default];

  config = lib.optionalAttrs desktopEnabled {
    programs.walker = {
      enable = true;
      runAsService = true;

      config = {
        close_when_open = true;
        click_to_close = true;
        selection_wrap = true;
        disable_mouse = false;
        theme = "default";

        placeholders = {
          default = {
            input = "Search";
            list = "No results";
          };
          desktopapplications = {
            input = "Launch";
            list = "No applications";
          };
          files = {
            input = "Files";
            list = "No files";
          };
          runner = {
            input = "Run command";
            list = "No commands";
          };
          clipboard = {
            input = "Clipboard";
            list = "Clipboard empty";
          };
          bitwarden = {
            input = "Bitwarden";
            list = "Vault locked or empty";
          };
          windows = {
            input = "Windows";
            list = "No windows";
          };
        };

        keybinds = {
          close = ["Escape"];
          next = ["Down" "Tab"];
          previous = ["Up" "ISO_Left_Tab"];
          toggle_exact = ["ctrl e"];
          resume_last_query = ["ctrl r"];
          show_actions = ["alt j"];
          quick_activate = ["F1" "F2" "F3" "F4"];
        };

        providers = {
          default = [
            "desktopapplications"
            "calc"
            "runner"
            "commands"
          ];
          empty = ["desktopapplications"];
          max_results = 40;

          sets = {
            launcher = {
              default = [
                "desktopapplications"
                "calc"
                "runner"
                "commands"
              ];
              empty = ["desktopapplications"];
            };
            files = {
              default = ["files"];
              empty = ["files"];
            };
            commands = {
              default = [
                "runner"
                "commands"
              ];
              empty = ["runner"];
            };
            clipboard = {
              default = ["clipboard"];
              empty = ["clipboard"];
            };
            bitwarden = {
              default = ["bitwarden"];
              empty = ["bitwarden"];
            };
            windows = {
              default = ["windows"];
              empty = ["windows"];
            };
          };

          max_results_provider = {
            desktopapplications = 12;
            files = 24;
            runner = 16;
            clipboard = 20;
            bitwarden = 20;
            windows = 20;
          };

          prefixes = [
            {
              prefix = ";";
              provider = "providerlist";
            }
            {
              prefix = ">";
              provider = "runner";
            }
            {
              prefix = "/";
              provider = "files";
            }
            {
              prefix = ":";
              provider = "clipboard";
            }
            {
              prefix = "$";
              provider = "windows";
            }
            {
              prefix = "!";
              provider = "bitwarden";
            }
            {
              prefix = "=";
              provider = "calc";
            }
          ];

          clipboard.time_format = "relative";
        };
      };

      elephant = {
        providers = [
          "bitwarden"
          "calc"
          "clipboard"
          "desktopapplications"
          "files"
          "providerlist"
          "runner"
          "windows"
        ];
      };
    };

    home.packages = with pkgs; [
      bitwarden-cli
      libqalculate
      wtype
    ];
  };
}
