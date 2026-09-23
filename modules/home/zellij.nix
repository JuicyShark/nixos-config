_: {
  programs.zellij = {
    enable = true;

    # Starting Zellij is intentional: ordinary shells stay ordinary shells.
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableZshIntegration = false;
    attachExistingSession = false;
    exitShellOnExit = false;

    settings = {
      #default_layout = "compact";
      #default_mode = "locked";
      on_force_close = "detach";

      mouse_mode = true;
      focus_follows_mouse = false;
      mouse_click_through = false;
      advanced_mouse_actions = true;
      mouse_hover_effects = true;

      pane_frames = true;
      auto_layout = true;
      stacked_resize = true;
      scroll_buffer_size = 50000;

      copy_clipboard = "system";
      copy_on_select = true;
      osc8_hyperlinks = true;
      styled_underlines = true;
      support_kitty_keyboard_protocol = true;
      visual_bell = true;

      session_serialization = true;
      serialize_pane_viewport = false;
      serialization_interval = 60;
      mirror_session = false;

      show_startup_tips = false;
      show_release_notes = false;
      simplified_ui = false;

      web_server = false;
      web_sharing = "disabled";
    };
  };
}
