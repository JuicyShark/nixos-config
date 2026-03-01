{pkgs, ...}: {
  users.defaultUserShell = pkgs.zsh;

  environment = {
    shells = with pkgs; [
      zsh
      bash
    ];

    systemPackages = with pkgs; [
      jq
      fd
      xh
      file
      timg
      dig
      mtr
      whois
      hwinfo
      duf
      stress
      hdparm
      fastfetch
      cmatrix
      p7zip
      peaclock
      tealdeer
      ffmpeg
      imagemagick
      nix-init
      nix-update
      nix-search-cli
      nix-tree
      nix-inspect
      opencode
    ];
  };

  environment.pathsToLink = [
    "/share/zsh"
    "/share/bash-completion"
  ];
  programs = {
    neovim.enable = true;
    zsh.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
