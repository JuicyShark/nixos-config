{
  ports,
  homeProfiles,
  config,
  pkgs,
  lib,
  ...
}: let
  hostKeys = {
    fallarbor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHPsx9Mg7qBNYwHsyECMf1h6xFRxcrxBLuS0GSPxmk8A";
    mac = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRb3ffUy38yem/rXxEn1cLHDGajmU7roZ5V3Uv3QaT4";
    zues = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQOb2XaMyLNZNRKvrfcwxVgeIF3rqsSNyY3Kldv735z";
  };

  username = config.modules.profile.username;
  homeDirectory = "/home/${username}";
  uwsm = lib.getExe pkgs.uwsm;
  gitDataDir = "/srv/smol/git";
  jellyfinDataDir = "/var/lib/jellyfin";
  jellyfinCacheDir = "/var/cache/jellyfin";
in {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/system.nix
    ../../modules/common/shell.nix
    ../../modules/nixos/desktop
    ./audio.nix
    ../../modules/nixos/shairport.nix
    ../../modules/common/stylix.nix
    ../../modules/nixos/fonts.nix
    ../../modules/nixos/glance.nix
    ../../modules/nixos/monitoring
    ../../modules/nixos/nfs.nix
    ../../modules/common/local-models.nix
    ../../modules/nixos/nymvpn.nix
    ../../modules/nixos/tether.nix
  ];

  assertions = [
    {
      assertion = lib.versions.major pkgs.jellyfin.version == "12";
      message = "The migrated Jellyfin database must only be opened by Jellyfin 12.";
    }
  ];

  environment = {
    systemPackages = with pkgs; [
      lm_sensors
      nvme-cli
      smartmontools
      # AMD GPU tooling
      radeontop
      vulkan-tools
      mesa-demos
      n64recomp
      libimobiledevice
      ifuse
      wl-clipboard
    ];
  };
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
      mac = {
        hostNames = [
          "imac-machop"
          "192.168.1.47"
        ];
        publicKey = hostKeys.mac;
      };
      fallarbor = {
        hostNames = [
          "fallarbor"
          "100.112.235.76"
        ];
        publicKey = hostKeys.fallarbor;
      };
    };

    gamemode.settings = {
      general = {
        desiredgov = "performance";
        renice = 10;
        softrealtime = "auto";
        inhibit_screensaver = 1;
      };

      cpu = {
        park_cores = "no";
        pin_cores = "yes";
      };

      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        # card0 is the UHD 770; card1 is the RX 7800 XT driving the displays.
        gpu_device = 1;
        amd_performance_level = "high";
      };
    };
  };

  networking = {
    hostName = "leo";
    domain = "home.arpa";

    resolvconf.extraOptions = [
      "timeout:1"
      "attempts:1"
    ];
    firewall.interfaces.enp7s0.allowedTCPPorts = [
      ports.alloy
      ports.exporters.node
    ];
    firewall.extraInputRules = ''
      ip saddr { 192.168.1.0/24, 100.64.0.0/10 } tcp dport {
        ${toString ports.sunshine.https},
        ${toString ports.sunshine.http},
        ${toString ports.sunshine.web},
        ${toString ports.sunshine.rtsp}
      } accept comment "Sunshine from LAN and Tailscale"
      ip saddr { 192.168.1.0/24, 100.64.0.0/10 } udp dport {
        ${toString ports.sunshine.video},
        ${toString ports.sunshine.control},
        ${toString ports.sunshine.audio},
        ${toString ports.sunshine.mic},
        ${toString ports.sunshine.rtsp}
      } accept comment "Sunshine streams from LAN and Tailscale"
    '';
    hosts."192.168.1.99" = [
      "zues"
      "zues.home.arpa"
    ];
  };
  home-manager.users.juicy.modules.desktop.hyprland = {
    sizing = "ultrawide";
    keyboard = "moonlander";
    primaryMonitor = "DP-2";
    tvMonitor = "HDMI-A-2";
    autostartApplications = true;
    applicationPlacement = true;
  };
  home-manager.sharedModules =
    homeProfiles.desktop
    ++ [
      ../../modules/home/qutebrowser.nix
      ./noctalia.nix
      {
        modules.desktop.hyprland.monitors = [
          {
            output = "DP-2";
            mode = "preferred";
            position = "0x0";
            scale = 1;
          }
          {
            output = "HDMI-A-2";
            mode = "1920x1080@60";
            position = "auto-center-right";
            scale = 1;
            disabled = true;
          }
          {
            output = "iPad";
            mode = "2420x1668@100";
            position = "auto";
            scale = 2;
            disabled = true;
          }
        ];
      }
    ];

  boot = {
    tmp.useTmpfs = true;
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = ["pcie_aspm=off"];
    #binfmt.emulatedSystems = ["aarch64-linux"];
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  modules = {
    profile = {
      flakePath = "/mnt/smol/nixos-config";
    };
    system = {
      media.enable = true;
    };
    shell = {
      atuin.syncUrl = "http://atuin.home.arpa";
      admin.enable = true;
      dev.enable = true;
    };
    desktop = {
      enable = true;
      applications.enable = true;
      gaming.enable = true;
      media.jellyfinMpvShim.enable = true;
      streaming.enable = true;
      terminalFileChooser.enable = true;
    };
    monitoring = {
      host.enable = true;
    };
    localModels = {
      enable = true;
      endpoint = "http://192.168.1.47:11434";
    };
    haPresence = {
      enable = true;
      deviceId = "leo_presence";
      brokerHost = "192.168.1.48";
      username = "homeassistant";
    };
    shairport = {
      enable = true;
      name = "Max Linux";
    };
    tether = {
      enable = true;
      interface = "enp7s0";
    };
    nfs = {
      exportPath = "/srv/smol";
      allowedHosts = [
        "192.168.1.14"
        "192.168.1.47"
        "192.168.1.52"
        "192.168.1.99"
      ];
      firewallInterfaces = [
        "enp7s0"
      ];
      additionalExports = [
        {
          path = "/srv/smol/backups/home-assistant";
          allowedHosts = ["192.168.1.48"];
        }
      ];
    };
  };
  services = {
    gitolite = {
      enable = true;
      dataDir = gitDataDir;
      user = "git";
      group = "git";
      adminPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILUlQ0gc5NIpsO3qPU7NR9NF8DobGXlhlmVzP944USPC juicy@leo";
      extraGitoliteRc = ''
        $RC{UMASK} = 0027;
        $RC{SITE_INFO} = 'leo private git';
      '';
    };

    # The Mac owns Jellyfin; retain Leo's state for migration rollback.
    jellyfin = {
      enable = false;
      package = pkgs.jellyfin;
      dataDir = jellyfinDataDir;
      cacheDir = jellyfinCacheDir;
      openFirewall = false;
    };

    lact.enable = true;
    nymvpn.enable = true;
    usbmuxd.enable = true;
    udev.packages = [pkgs.libimobiledevice];

    greetd.settings.initial_session = {
      user = username;
      command = "${uwsm} start -e -D Hyprland hyprland.desktop";
    };

    syncthing = {
      enable = false;
      user = username;
      dataDir = homeDirectory;
      guiAddress = "127.0.0.1:${toString ports.syncthing}";
      openDefaultPorts = true;
    };

    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [
        "/"
        "/srv/smol"
      ];
    };

    sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = false;
      openFirewall = false;
      settings = {
        capture = "wlr";
        encoder = "vaapi";
        origin_web_ui_allowed = "lan";
        upnp = "disabled";
        stream_audio = "disabled";
        fec_percentage = 0;
        hevc_mode = 1;
        av1_mode = 1;
        max_bitrate = 35000;
        output_name = "DP-2";
        port = ports.sunshine.http;
      };
      applications.apps = let
        sunshineHyprlandStream = pkgs.writeShellScriptBin "sunshine-hyprland-stream" ''
          set -eu

          action="''${1:-}"
          remote="''${2:-false}"

          case "$remote" in
            true|false) ;;
            *)
              echo "usage: sunshine-hyprland-stream start true|false | stop" >&2
              exit 2
              ;;
          esac

          case "$action" in
            start)
              exec ${uwsm} app -- ${lib.getExe' config.programs.hyprland.package "hyprctl"} eval \
                "Juicy.sunshine.setStreaming(true, $remote)"
              ;;
            stop)
              exec ${uwsm} app -- ${lib.getExe' config.programs.hyprland.package "hyprctl"} eval \
                'Juicy.sunshine.setStreaming(false, false)'
              ;;
            *)
              echo "usage: sunshine-hyprland-stream start true|false | stop" >&2
              exit 2
              ;;
          esac
        '';
      in [
        {
          name = "Desktop";
          image-path = "desktop.png";
          prep-cmd = [
            {
              do = "${sunshineHyprlandStream}/bin/sunshine-hyprland-stream start false";
              undo = "${sunshineHyprlandStream}/bin/sunshine-hyprland-stream stop";
            }
          ];
        }
        {
          name = "Remote";
          image-path = "desktop.png";
          prep-cmd = [
            {
              do = "${sunshineHyprlandStream}/bin/sunshine-hyprland-stream start true";
              undo = "${sunshineHyprlandStream}/bin/sunshine-hyprland-stream stop";
            }
          ];
        }
      ];
    };

    journald.settings.Journal = {
      SystemMaxUse = "512M";
      RuntimeMaxUse = "256M";
      MaxFileSec = "7day";
      RateLimitIntervalSec = "30s";
      RateLimitBurst = 1000;
    };
    fstrim.enable = true;
    irqbalance.enable = true;
  };

  # Preserve the Mac paths already stored in the migrated database while
  # resolving them through Leo's Linux NFS mount.
  systemd.tmpfiles.rules = [
    "d ${gitDataDir} 0750 git git - -"
    "d /srv/smol/backups 0700 ${username} users -"
    "d /srv/smol/backups/home-assistant 0700 ${username} users -"
    "d /Volumes 0755 root root -"
    "L+ /Volumes/chonk - - - - /mnt/chonk"
  ];

  systemd.services.gitolite-init.unitConfig.RequiresMountsFor = [gitDataDir];

  systemd.services.jellyfin = lib.mkIf config.services.jellyfin.enable {
    after = ["mnt-chonk.mount"];
    requires = ["mnt-chonk.mount"];
    # This host owns an existing migrated library. Missing state requires an
    # explicit restore, never an empty library or an import from /tmp.
    preStart = lib.mkBefore ''
      if [ ! -s ${lib.escapeShellArg "${jellyfinDataDir}/data/jellyfin.db"} ]; then
        echo "Jellyfin state is missing; restore the existing library state before starting the server" >&2
        exit 1
      fi
    '';
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
    "/mnt/smol" = {
      device = "/srv/smol";
      fsType = "none";
      options = ["bind"];
    };

    "/mnt/chonk" = {
      device = "192.168.1.99:/srv/chonk";
      fsType = "nfs";
      options = [
        "nfsvers=4"
        "hard"
        "timeo=600"
        "retrans=2"
        "fsc"
        "x-systemd.automount"
        "nofail"
        "_netdev"
      ];
    };
  };
  hardware = {
    keyboard.zsa.enable = true;
    steam-hardware.enable = true;
    openrazer = {
      enable = true;
      users = [username];
      devicesOffOnScreensaver = true;
    };
  };

  system.stateVersion = "25.11";
}
