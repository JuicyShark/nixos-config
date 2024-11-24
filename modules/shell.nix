{pkgs, ...}: {
  users.defaultUserShell = pkgs.zsh;

  environment = {
    shells = with pkgs; [fish zsh];

    systemPackages = with pkgs; [
      jq
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
      sudachi-rs
      npm-check-updates
      microfetch
      onefetch
      asciiquarium-transparent
      cmatrix
      p7zip
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
    ];
  };

  environment.pathsToLink = ["/share/zsh"];
  programs = {
    fish.enable = true;
    zsh.enable = true;
    neovim.enable = true;

    direnv = {
      enable = true;
      silent = true;
    };
  };
}
