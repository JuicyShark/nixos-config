_: {
  programs.btop = {
    enable = true;
    settings = {
      # The Moonlander Nav layer already provides a physical arrow diamond.
      vim_keys = false;
      rounded_corners = true;
      update_ms = 1000;
      proc_tree = false;
      proc_per_core = true;
    };
  };
}
