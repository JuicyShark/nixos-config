{lib, ...}: {
  programs = {
    bat = {
      enable = true;
      config.theme = lib.mkForce "base16";
    };

    btop = {
      enable = true;
      settings = {
        # The Moonlander Nav layer already provides a physical arrow diamond.
        update_ms = 1000;
        proc_per_core = true;
      };
    };

    eza = {
      enable = true;
      icons = "auto";
      extraOptions = [
        "--group-directories-first"
        "--no-quotes"
      ];
    };

    ripgrep = {
      enable = true;
      arguments = [
        "--max-columns=2000"
        "--smart-case"
      ];
    };

    zoxide.enable = true;
  };
}
