{
  lib,
  pkgs,
  osConfig,
  ...
}:
lib.mkIf ((osConfig.modules.desktop.enable or false) || pkgs.stdenv.isDarwin) {
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
      }
      // {
        dynamic_background_opacity = true;

        window_padding_width = 5;
        single_window_padding_width = 0;
        placement_strategy = "bottom-left";
        hide_window_decorations = "yes";

        visual_window_select_characters = "arstneio12345";

        scrollback_pager = "less --chop-long-lines --raw-control-chars +INPUT_LINE_NUMBER";

        # Performance
        sync_to_monitor = "yes";
      };
    keybindings = {
      "ctrl+c" = "copy_or_interrupt";
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+v" = "paste_from_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "kitty_mod+w" = "close_os_window";
      "kitty_mod+enter" = "launch --cwd=current --type=os-window";
      "kitty_mod+f" = "show_scrollback";
    };
  };
}
