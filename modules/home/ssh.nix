{config, ...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        compression = true;
        forwardAgent = false;
        hashKnownHosts = true;
        serverAliveInterval = 30;
        serverAliveCountMax = 3;
        controlMaster = "auto";
        controlPersist = "10m";
        controlPath = "~/.ssh/control-%C";
        identityFile = [
          "~/.ssh/id_ed25519"
          "~/.ssh/id_rsa"
        ];
        identitiesOnly = true;
        user = config.home.username;
      };

      leo.hostname = "leo.home.arpa";
      zues.hostname = "zues.home.arpa";
      fallarbor.hostname = "fallarbor";
    };
  };
}
