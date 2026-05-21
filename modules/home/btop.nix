_: {
  programs.btop = {
    enable = true;
    settings = {
      vim_keys = true;
      rounded_corners = true;
      update_ms = 1000;
      proc_tree = false;
      proc_per_core = true;
    };
  };
}
