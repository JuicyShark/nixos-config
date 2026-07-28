{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}: let
  cfg = config.modules.terminal;
  terminalEnabled = (osConfig.modules.desktop.enable or false) || pkgs.stdenv.isDarwin;
in {
  options.modules.terminal = {
    backend = lib.mkOption {
      type = lib.types.enum [
        "kitty"
        "ghostty"
      ];
      default = "kitty";
      description = "Terminal emulator used by desktop launchers and terminal applications.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default =
        if cfg.backend == "kitty"
        then pkgs.kitty
        else pkgs.ghostty;
      description = "Package implementing the selected terminal backend.";
    };
  };

  config = lib.mkIf terminalEnabled (lib.mkMerge [
    {
      assertions = [
        {
          assertion = !(pkgs.stdenv.isDarwin && cfg.backend == "ghostty");
          message = "modules.terminal.backend = \"ghostty\" is unsupported on macOS because Ghostty cannot launch from its CLI there.";
        }
      ];

      home.sessionVariables.TERMINAL = lib.getExe cfg.package;
    }

    (lib.mkIf (cfg.backend == "ghostty") {
      programs.ghostty = {
        enable = true;
        settings = {
          keybind = [
            "page_up=unbind"
            "page_down=unbind"
            "shift+page_up=scroll_page_up"
            "shift+page_down=scroll_page_down"
          ];
        };
      };
    })

    (lib.mkIf (cfg.backend == "kitty") {
      # Kitty owns its font metrics locally; Stylix continues to own colors and
      # opacity without emitting an earlier, overridden font declaration.
      stylix.targets.kitty.fonts.enable = false;

      programs.kitty = {
        enable = true;
        shellIntegration.enableZshIntegration = true;
        settings =
          {
            term = "xterm-kitty";
            enable_audio_bell = false;
            close_on_child_death = true;
            confirm_os_window_close = 0;
            cursor_blink_interval = 0;

            editor = "nvim";
            notify_on_cmd_finish = "unfocused";
            clear_all_shortcuts = true;
            kitty_mod = "ctrl+alt";
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            wayland_titlebar_color = "background";
            wayland_enable_ime = false;
            listen_on = "unix:\${XDG_RUNTIME_DIR}/kitty-{kitty_pid}";
            allow_remote_control = "socket-only";
            hide_window_decorations = "yes";
          }
          // lib.optionalAttrs pkgs.stdenv.isDarwin {
            macos_titlebar_color = "system";
            macos_quit_when_last_window_closed = "no";
            background_blur = 32;
          }
          // {
            dynamic_background_opacity = true;

            font_family = "Mononoki Nerd Font";
            bold_font = "auto";
            italic_font = "auto";
            bold_italic_font = "auto";
            font_size = 14;
            "modify_font cell_height" = "115%";
            "modify_font cell_width" = "102%";

            window_padding_width = 10;
            single_window_padding_width = 0;
            placement_strategy = "bottom-left";

            visual_window_select_characters = "arstneio12345";

            scrollback_pager = "less --chop-long-lines --raw-control-chars +INPUT_LINE_NUMBER";

            sync_to_monitor = "yes";
          };
        keybindings = {
          "ctrl+c" = "copy_or_interrupt";
          "ctrl+shift+c" = "copy_to_clipboard";
          "ctrl+shift+v" = "paste_from_clipboard";
          "ctrl+shift+f3" = "command_palette";
          "kitty_mod+slash" = "command_palette";
          "kitty_mod+w" = "close_os_window";
          "kitty_mod+enter" = "launch --cwd=current --type=os-window";
          "kitty_mod+f" = "show_scrollback";
          "shift+page_up" = "scroll_page_up";
          "shift+page_down" = "scroll_page_down";
        };
      };
    })
  ]);
}
