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

  inputLeapPort = 24800;
  inputLeapConfig = pkgs.writeText "input-leap.conf" ''
    section: screens
      leo:
      mac:
    end

    section: links
      leo:
        right = mac
      mac:
        left = leo
    end
  '';
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
    nfs
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
    input-leap
    # Intel CPU diagnostics
    intel-gpu-tools
  ];

  programs = {
    ssh.knownHosts = {
      zues = {
        hostNames = [
          "zues"
          "zues.home.arpa"
          "192.168.1.99"
        ];
        publicKey = hostKeys.zues;
      };
      fallarbor = {
        hostNames = [
          "fallarbor"
          "100.112.235.76"
        ];
        publicKey = hostKeys.fallarbor;
      };
    };

    nh.flake = "/mnt/smol/nixos-config";

    gamemode.settings = {
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
  };

  networking = {
    hostName = "leo";
    hosts."192.168.1.99" = [
      "zues"
      "zues.home.arpa"
    ];
  };
  environment.variables.FLAKE = "/mnt/smol/nixos-config";
  home-manager.sharedModules = homeProfiles.desktop;

  # lact daemon for AMD GPU fan/power control
  systemd.services.lactd = {
    description = "AMDGPU Control Daemon";
    after = ["multi-user.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig.ExecStart = "${pkgs.lact}/bin/lact daemon";
    enable = true;
  };

  modules = {
    profile.hashedPasswordFile = config.age.secrets.juicy-password.path;
    system = {
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
    };
    emacs.enable = true;
    recomp.enable = true;
    glance.enable = true;
    ios.enable = true;
    haPresence = {
      enable = true;
      deviceId = "leo_presence";
      brokerHost = "192.168.1.49";
      username = "homeassistant";
      idleTimeout = 300;
      sleepTimeout = 900;
    };
    shairport = {
      enable = true;
      name = "Max Linux";
    };
    shell.atuin.syncUrl = "http://192.168.1.99:8888";
    nfs = {
      exportPath = "/srv/smol";
      firewallInterfaces = [
        "enp7s0"
        "tailscale0"
      ];
    };
  };
  services = {
    syncthing = {
      enable = true;
      user = "juicy";
      dataDir = "/home/juicy";
      guiAddress = "127.0.0.1:${toString config.modules.ports.syncthing}";
      openDefaultPorts = true;
    };

    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "client";
      extraUpFlags = [
        "--login-server=https://ts.nixlab.au"
        "--accept-dns=false"
        "--accept-routes"
      ];
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

  networking.firewall.allowedTCPPorts = [inputLeapPort];

  systemd.user.services.input-leap-server = {
    description = "Input Leap server";
    after = [
      "network-online.target"
      "graphical-session.target"
      "xdg-desktop-portal.service"
      "xdg-desktop-portal-hyprland.service"
    ];
    wants = [
      "network-online.target"
      "xdg-desktop-portal.service"
      "xdg-desktop-portal-hyprland.service"
    ];
    wantedBy = ["graphical-session.target"];
    serviceConfig = {
      ExecStart = "${pkgs.input-leap}/bin/input-leaps -f -c ${inputLeapConfig} -n leo -a :${toString inputLeapPort}";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  fileSystems = {
    "/mnt/games" = {
      device = "/dev/disk/by-uuid/3855cf03-6c1b-4e03-baed-5818ab1f6066";
      fsType = "ext4";
      options = [
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
      device = "/srv/smol/torrents";
      fsType = "none";
      options = [
        "bind"
        "nofail"
        "x-systemd.automount"
        "x-systemd.requires-mounts-for=/srv/smol"
      ];
    };

    "/mnt/chonk" = {
      device = "192.168.1.99:/srv/chonk";
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
