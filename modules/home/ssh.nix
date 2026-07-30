{config, lib, ...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        Compression = true;
        ForwardAgent = false;
        HashKnownHosts = true;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
        ControlMaster = "auto";
        ControlPersist = "10m";
        ControlPath = "~/.ssh/control-%C";
        IdentityFile = [
          "~/.ssh/id_ed25519"
          "~/.ssh/id_rsa"
        ];
        IdentitiesOnly = true;
        User = config.home.username;
      };

      leo.HostName = "leo.home.arpa";
      zues.HostName = "zues.home.arpa";
      fallarbor.HostName = "fallarbor";
    };
  };

  # OpenSSH refuses a config symlink whose Nix-store target appears to be
  # owned by another UID. Materialize Home Manager's generated config after
  # linking it so `ssh` can use the normal config path without `-F` workarounds.
  home.file.".ssh/config".force = true;
  home.activation.materializeSshConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
    # The previous activation leaves a regular file here, so it can be both
    # the source and destination. Copy first, then replace it atomically.
    ssh_config_temp="$(mktemp "$HOME/.ssh/config.XXXXXX")"
    trap 'rm -f "$ssh_config_temp"' EXIT
    install -m 600 "$HOME/.ssh/config" "$ssh_config_temp"
    mv -f "$ssh_config_temp" "$HOME/.ssh/config"
  '';
}
