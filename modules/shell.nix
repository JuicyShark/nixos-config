{ pkgs, ... }:
{
  users.defaultUserShell = pkgs.fish;

  environment = {
    shells = with pkgs; [
      fish
      zsh
    ];

    systemPackages = with pkgs; [
      jq
      shell-gpt
      fd
      xh
      file
      timg
      rustscan
      yt-dlp
      dig
      mtr
      whois
      killall
      hwinfo
      duf
      stress
      hdparm
      jpegoptim
      fastfetch
      onefetch
      asciiquarium-transparent
      cmatrix
      p7zip
      peaclock
      rsync
      rclone
      ffmpeg
      imagemagick
      smartmontools
      bluetui
      nixpkgs-review
      nix-init
      nix-update
      nix-search-cli
      nix-tree
      gcc
      rustc
      rustfmt
      cargo
      nodejs
      nix-inspect
      sherlock # Search Social Media Names
      lemonade
      zoxide
    ];
  };

  environment.pathsToLink = [ "/share/fish" ];
  environment.variables = {
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
  };
  programs = {
    fish.enable = true;
    neovim.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableFishIntegration = true;
      silent = true;
    };
  };
}
