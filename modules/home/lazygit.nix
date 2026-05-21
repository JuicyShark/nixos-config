_: {
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        # Stylix will manage the theme via its lazygit integration if enabled;
        # these defaults are overridden by the stylix home-manager module.
        theme = {
          activeBorderColor = [
            "green"
            "bold"
          ];
          inactiveBorderColor = ["white"];
          selectedLineBgColor = ["blue"];
        };
      };

      keybinding = {
        universal = {
          # Arrow-key navigation consistent with neovim bindings
          prevItem = "<up>";
          nextItem = "<down>";
          prevBlock = "<left>";
          nextBlock = "<right>";
          # vim-style hjkl alternatives
          prevItem-alt = "k";
          nextItem-alt = "j";
          prevBlock-alt = "h";
          nextBlock-alt = "l";
        };
        commits = {
          # Open interactive rebase at selected commit (consistent with neovim workflow)
          interactiveRebase = "i";
        };
      };
    };
  };
}
