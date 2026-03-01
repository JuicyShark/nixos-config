{
  lib,
  osConfig,
  ...
}:
lib.mkIf (builtins.elem "desktop" osConfig.modules.system.roles) {
  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    settings = {
      term = "xterm-kitty";
      enable_audio_bell = false;
      close_on_child_death = true;
      cursor_blink_interval = 0;

      editor = "nvim";
      notify_on_cmd_finish = "unfocused";
      clear_all_shortcuts = true;
      kitty_mod = "ctrl+alt";

      enabled_layouts = "fat, tall, vertical";
      wayland_titlebar_color = "background";
      wayland_enable_ime = false;

      allow_remote_control = true;
      listen_on = "unix:\${XDG_RUNTIME_DIR}/kitty";
      dynamic_background_opacity = true;

      window_padding_width = 5;
      single_window_padding_width = 0;
      placement_strategy = "bottom-left";
      tab_bar_margin_width = 5;
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
      "kitty_mod+t" = "launch --cwd=current --type=tab";
      "kitty_mod+w" = "close_window";
      "kitty_mod+shift+w" = "close_tab";
      "kitty_mod+[" = "previous_tab";
      "kitty_mod+]" = "next_tab";
      "kitty_mod+space" = "next_layout";
      "kitty_mod+shift+space" = "last_layout";
    };
  };
}
