{pkgs, ...}: {
  users.defaultUserShell = pkgs.fish;

  environment = {
    shells = with pkgs; [fish zsh];

    systemPackages = with pkgs; [
      jq
      shell-gpt
      fd
      xh
      file
      timg
      choose
      rustscan
      yt-dlp
      timer
      dig
      mtr
      mediainfo
      fdupes
      whois
      killall
      hwinfo
      duf
      stress
      hdparm
      jpegoptim
      npm-check-updates
      microfetch
      onefetch
      asciiquarium-transparent
      cmatrix
      p7zip
      peaclock
      unar
      rsync
      rclone
      ffmpeg
      imagemagick
      smartmontools
      restic
      borgbackup
      zbar
      phraze
      lychee
      bluetui
      ventoy
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
      monolith
      haylxon
      nix-inspect
      sherlock
      remind
      zoxide
    ];
  };

  environment.pathsToLink = ["/share/fish"];
  environment.variables = {
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
  };
  programs = {
    fish.enable = true;
    neovim.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      #silent = true;
    };
  };
}
