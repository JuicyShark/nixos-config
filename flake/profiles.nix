{homeModules}: rec {
  cli = with homeModules; [
    atuin
    bat
    btop
    eza
    fastfetch
    fzf
    git
    ripgrep
    ssh
    starship
    tmux
    zoxide
    zsh
  ];

  workstationCli =
    cli
    ++ (with homeModules; [
      editorconfig
      lazygit
      neovim
      yazi
    ]);

  desktop =
    workstationCli
    ++ (with homeModules; [
      chromium
      desktop-apps
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
      xdg-desktop-entries
      xdg-user-dirs
      xresources
    ]);

  darwin =
    workstationCli
    ++ (with homeModules; [
      emacs
      kitty
      mpv
      xdg-user-dirs
    ]);
}
