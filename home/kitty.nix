{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:

let
  inherit (config.lib.stylix.colors.withHashtag) base00;
in
{
  programs.kitty = lib.mkIf osConfig.modules.desktop.enable {
    shellIntegration.enableZshIntegration = true;
    enable = true;
    settings = {
      term = "xterm-kitty";
      enable_audio_bell = false;
      close_on_child_death = true;
      cursor_blink_interval = 0;

      editor = "nvim";
      notify_on_cmd_finish = "unfocused";
      clear_all_shortcuts = true;

      enabled_layouts = "fat, tall, vertical";
      wayland_titlebar_color = "background";
      wayland_enable_ime = false;

      allow_remote_control = true;
      listen_on = "unix:/tmp/kitty";
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
      "alt" = "kitty_mod";
      "ctrl+c" = "copy_or_interrupt";
      "ctrl+shift+c" = "copy_to_clipboard";
      "kitty_mod+c" = "copy_or_interrupt";
      "ctrl+v" = "paste_from_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "kitty_mod+v" = "paste_from_clipboard";

    };

    extraConfig = ''
      tab_bar_background ${base00}
      inactive_tab_background ${base00}
    '';
  };

}
