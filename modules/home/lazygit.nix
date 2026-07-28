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
          # The Moonlander Nav layer supplies arrows, Home, End, PageUp and
          # PageDown. Keep movement on those physical controls and leave the
          # Colemak letters available for Lazygit's actual commands.
          prevItem = "<up>";
          nextItem = "<down>";
          prevBlock = "<left>";
          nextBlock = "<right>";
          prevItem-alt = "<disabled>";
          nextItem-alt = "<disabled>";
          prevBlock-alt = "<disabled>";
          nextBlock-alt = "<disabled>";
          scrollLeft = "<shift+left>";
          scrollRight = "<shift+right>";
          scrollUpMain-alt1 = "<disabled>";
          scrollDownMain-alt1 = "<disabled>";
          scrollUpMain-alt2 = "<disabled>";
          scrollDownMain-alt2 = "<disabled>";
        };
        commits = {
          moveDownCommit = "<alt+down>";
          moveUpCommit = "<alt+up>";
          interactiveRebase = "i";
        };
        main = {
          prevHunk = "<left>";
          nextHunk = "<right>";
        };
      };
    };
  };
}
