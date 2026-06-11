{self, ...}: let
  hm = self.homeModules;
in {
  _module.args.homeProfiles = rec {
    cli = with hm; [
      atuin
      bat
      btop
      editorconfig
      eza
      fastfetch
      fzf
      git
      lazygit
      neovim
      ripgrep
      ssh
      starship
      tmux
      yazi
      zoxide
      zsh
    ];

    desktop =
      cli
      ++ (with hm; [
        chromium
        emacs
        gtk
        ha-presence
        hyprland
        kitty
        mime-apps
        mpv
        noctalia-shell
        obs
        qutebrowser
        rbw
        shairport
        walker
        xdg-desktop-entries
        xdg-user-dirs
        xresources
      ]);

    darwin =
      cli
      ++ (with hm; [
        emacs
        kitty
        mpv
        qutebrowser
        xdg-user-dirs
      ]);
  };
}
