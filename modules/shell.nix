{ pkgs, ... }:
{
  users.defaultUserShell = pkgs.nushell;

  environment = {
    shells = with pkgs; [
      nushell
      bash
    ];

    systemPackages = with pkgs; [
      jq
      shell-gpt
      fd
      xh
      file
      timg
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
      nix-init
      nix-update
      nix-search-cli
      nix-tree
      nix-inspect
      zoxide
      zellij
    ];
  };

  environment.pathsToLink = [ "/share/fish" ];
  environment.variables = {
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
  };
  environment.interactiveShellInit = ''
    if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
      if uwsm check may-start && uwsm select; then
        exec uwsm start default
      fi
    fi
  '';
  programs = {
    neovim.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      #enableNushellIntegration = true;
      silent = true;
    };
  };
}
