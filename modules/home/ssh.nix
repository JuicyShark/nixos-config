{config, ...}: {
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
}
