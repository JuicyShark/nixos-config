{
  self,
  homeProfiles,
  config,
  pkgs,
  ...
}: let
  loginHome = config.users.users.${config.modules.profile.username}.home;
  nfsMountRoot = "/Volumes";
in {
  imports = with self.darwinModules; [
    system
    shell
    stylix
    emacs
    jellyfin
    local-models
    minecraft
    ollama
  ];

  modules = {
    # The Mac keeps its own local checkout; smol is not a runtime dependency.
    profile.flakePath = "${config.users.users.${config.modules.profile.username}.home}/nixos-config";
    emacs.enable = false;
    shell.dev.enable = true;
    jellyfin = {
      enable = true;
      # A macOS LaunchDaemon running as a dedicated service account is denied
      # access to NFS volumes by the OS privacy layer. Run as the interactive
      # account that owns the mount instead.
      user = config.modules.profile.username;
      # Match the canonical media root used by Nixflix on zues. Existing
      # ~/chonk Jellyfin libraries resolve to this same autofs NFS mount.
      mediaDirectories = ["${nfsMountRoot}/chonk/media"];
    };
    minecraft.server = {
      enable = false;
      pack = "skyfactory5";
      publicAddress = "192.168.1.52:25565";
    };
    localModels = {
      enable = true;
      endpoint = "http://192.168.1.52:11434";
      defaultModel = "qwen3.5:9b";
    };
    ollama = {
      enable = true;
      # Bind only the trusted LAN address: Ollama's API has no authentication.
      listenAddress = "192.168.1.52";
      contextLength = 16384;
      maxLoadedModels = 1;
      parallelRequests = 1;
      recommendedModels = [
        "qwen3.5:9b"
        "embeddinggemma"
      ];
    };
  };

  networking.hostName = "mac";
  home-manager.sharedModules = homeProfiles.darwin;

  # Both NFS servers intentionally expose v4 only.  Keep the Darwin client
  # declaration here rather than relying on stale hand-written `/etc/fstab`
  # state (which was still forcing NFSv3), and ensure the targets exist before
  # macOS processes the fstab entries. `/mnt` lives on the sealed system
  # volume on current macOS releases; `/Volumes` is its writable mount space.
  environment.etc.fstab.text = ''
    # Jellyfin only reads this media tree. Fail boundedly across Zues NFS
    # restarts instead of wedging macOS processes on an indefinitely hard
    # mount; later reads retry normally once the server is available again.
    192.168.1.99:/srv/chonk ${nfsMountRoot}/chonk nfs ro,resvport,vers=4.1,soft,nolocallocks,timeo=50,retrans=2,tcp 0 0
    192.168.1.54:/srv/smol ${nfsMountRoot}/smol nfs rw,intr,resvport,vers=4.1,hard,tcp 0 0
  '';

  system.activationScripts.nfsMountPoints.text = ''
    /usr/bin/install -d -m 0755 ${nfsMountRoot}/chonk ${nfsMountRoot}/smol
    /bin/ln -sfn ${nfsMountRoot}/chonk ${loginHome}/chonk
  '';

  # Bootstrap Homebrew itself and provide the architecture-aware `brew`
  # launcher in /run/current-system/sw/bin.
  nix-homebrew = {
    enable = true;
    user = config.modules.profile.username;
    autoMigrate = true;
    trust.taps = ["deskflow/tap"];
  };

  homebrew = {
    enable = true;
    enableZshIntegration = true;

    taps = [
      "deskflow/tap"
    ];

    casks = [
      "deskflow"
    ];
  };

  # GNU userland parity with Linux hosts (prefixed as g* — gsed, gtar, gfind, etc.)
  environment.systemPackages = with pkgs; [
    coreutils-prefixed
    gnused
    gnutar
    findutils
    mas
    switchaudio-osx
  ];

  # Tailscale is installed and enrolled outside nix-darwin on this host.
  # If moving daemon ownership into Nix later, enroll against the standard
  # Tailscale control plane with: tailscale up --accept-routes --accept-dns=false
  services.tailscale.enable = false;
}
