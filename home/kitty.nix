let VARIABLES = import ../src/variables.nix; in {
  programs.kitty = {
    enable = true;

    settings = {
      enable_audio_bell = false;
      close_on_child_death = true;
      cursor_blink_interval = 0;

      open_url_with = VARIABLES.defaultBrowser;
      wayland_titlebar_color = "background";

      allow_remote_control = true;
      listen_on = "unix:/tmp/kitty";
      dynamic_background_opacity = true;

      window_padding_width = 5;
      tab_bar_margin_width = 5;
    };
  };

  xdg.configFile."kitty/diff.conf".text = ''
    map d scroll_to next-page
    map u scroll_to prev-page
    map g scroll_to start
    map G scroll_to end
  '';
}