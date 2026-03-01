{...}: {
  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      style = "compact";
      inline_height = 18;
      search_mode = "fuzzy";
      search_mode_shell_up_key_binding = "fuzzy";
      filter_mode = "global";
      filter_mode_shell_up_key_binding = "global";
      show_preview = false;
      show_help = false;
      show_tabs = false;
      sync_address = "http://zues.home.arpa:8888";
      sync_frequency = "10m";
      auto_sync = true;
      enter_accept = false;
      keymap_mode = "auto";
    };
  };
}
