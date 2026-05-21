{
  self,
  homeProfiles,
  config,
  pkgs,
  ...
}: let
  hostKeys = {
    fallarbor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHPsx9Mg7qBNYwHsyECMf1h6xFRxcrxBLuS0GSPxmk8A";
    zues = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQOb2XaMyLNZNRKvrfcwxVgeIF3rqsSNyY3Kldv735z";
  };
in {
  imports = with self.nixosModules; [
    system
    shell
    desktop
    pipewire
    recomp
    shairport
    stylix
    fonts
    emacs
    sunshine
    glance
    monitoring
    tailscale
    nfs
    impermanence
    ha-presence
    ios
  ];

  environment.systemPackages = with pkgs; [
    lm_sensors
    nvme-cli
    openvpn
    smartmontools
    # AMD GPU tooling
    lact # replaces: corectrl (modern daemon-based AMD GPU control)
    radeontop
    nvtopPackages.amd
    vulkan-tools
    mesa-demos
    # Intel CPU diagnostics
    intel-gpu-tools
  ];

  programs.ssh.knownHosts = {
    zues = {
      hostNames = [
        "zues"
        "zues.home.arpa"
        config.modules.network.hosts.zues
      ];
      publicKey = hostKeys.zues;
    };
    fallarbor = {
      hostNames = [
        "fallarbor"
        config.modules.network.hosts.fallarbor
      ];
      publicKey = hostKeys.fallarbor;
    };
  };

  # lact daemon for AMD GPU fan/power control
  systemd.services.lactd = {
    description = "AMDGPU Control Daemon";
    after = ["multi-user.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig.ExecStart = "${pkgs.lact}/bin/lact daemon";
    enable = true;
  };

  modules = {
    system = {
      flakePath = "/mnt/smol/nixos-config";
      hostName = "leo";
      hashedPasswordFile = config.age.secrets.juicy-password.path;
      homeModules = homeProfiles.desktop;
      keyboard.zsa = true;
      highMemory.enable = true;
    };
    desktop = {
      enable = true;
      bloat.enable = true;
      gaming.enable = true;
      guiFallback.enable = true;
      streaming.enable = true;
      sunshine.enable = true;
      primaryMonitor = {
        output = "DP-2";
        # The panel exposes the same EDID description on DP-2 and HDMI-A-2.
        # Match the primary display by output name so Hyprland defaults to DP-2.
        desc = null;
        wideColor = true;
      };
    };
    emacs.enable = true;
    recomp.enable = true;
    glance.enable = true;
    tailscale.enable = true;
    haPresence.enable = true;
    ios.enable = true;
    shairport.enable = true;
    shell.atuin.syncUrl = "http://${config.modules.network.hosts.zues}:8888";
    nfs = {
      exportPath = "/srv/smol";
      firewallInterfaces = [
        "enp7s0"
        "tailscale0"
      ];
    };
    impermanence = {
      enable = false; # not yet active — disk prep required first (see modules/nixos/impermanence.nix)
      rootUuid = "abe7aa06-2f9e-431c-a9f1-5029ff0c3c65";
      btrfsWipe = false;
    };
  };
  services = {
    syncthing = {
      enable = true;
      user = config.modules.system.username;
      dataDir = "/home/${config.modules.system.username}";
      guiAddress = "127.0.0.1:${toString config.modules.ports.syncthing}";
      openDefaultPorts = true;
    };

    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = ["/"];
    };

    hardware.openrgb = {
      enable = true;
      motherboard = "intel";
      package = pkgs.openrgb-with-all-plugins;
    };

    journald.extraConfig = ''
      SystemMaxUse=512M
      RuntimeMaxUse=256M
      MaxFileSec=7day
      RateLimitInterval=30s
      RateLimitBurst=1000
    '';
    fstrim.enable = true;
    irqbalance.enable = true;
  };

  programs.gamemode.settings = {
    general = {
      renice = 10;
      softrealtime = "auto";
      inhibit_screensaver = 1;
    };

    cpu = {
      governor = "performance";
      park_cores = "no";
      pin_cores = "yes";
      energy_performance_preference = "performance";
    };

    gpu = {
      apply_gpu_optimisations = "accept-responsibility";
      gpu_device = 0;
      amd_performance_level = "high";
    };
  };

  fileSystems = {
    "/mnt/games" = {
      device = "/dev/disk/by-uuid/100E4A9B7EF0C278";
      fsType = "ntfs3";
      options = [
        "uid=1000"
        "gid=100"
        "umask=022"
        "windows_names"
        "noatime"
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=5s"
      ];
    };

    "/mnt/games/SteamLibrary/steamapps/compatdata" = {
      device = "/home/juicy/.steam/steamcompat";
      fsType = "none";
      options = [
        "bind"
        "nofail"
        "x-systemd.automount"
      ];
    };

    "/srv/smol" = {
      device = "/dev/disk/by-uuid/85a1714c-447f-4324-99af-dc0bf3b16b3d";
      fsType = "btrfs";
      options = [
        "compress=zstd:3"
        "noatime"
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=15s"
      ];
    };

    "/mnt/torrents" = {
      device = "/dev/disk/by-uuid/b296f7f1-ac9e-411c-98ac-4d6b6b13a6b5";
      fsType = "btrfs";
      options = [
        "compress=zstd:3"
        "noatime"
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=15s"
      ];
    };

    "/mnt/chonk" = {
      device = "${config.modules.network.hosts.zues}:/srv/chonk";
      fsType = "nfs";
      options = [
        "nfsvers=4"
        "fsc"
        "x-systemd.automount"
        "nofail"
      ];
    };

    "/mnt/smol" = {
      device = "/srv/smol";
      fsType = "none";
      options = ["bind"];
    };
  };

  hardware.openrazer.enable = true;
  hardware.steam-hardware.enable = true;
}
