{
  self,
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

  inputLeapPort = 24800;
  username = config.modules.profile.username;
  homeDirectory = "/home/${username}";
  deskflowServerConfig = pkgs.writeText "deskflow-server.conf" ''
    section: screens
      leo:
      mac:
    end

    section: aliases
    end

    section: links
      leo:
        right = mac
      mac:
        left = leo
    end

    section: options
      protocol = synergy
      clipboardSharing = true
      clipboardSharingSize = 20480
    end
  '';
  deskflowSettings = pkgs.writeText "Deskflow.conf" ''
    [core]
    computerName=leo
    coreMode=2
    interface=192.168.1.54
    port=${toString inputLeapPort}
    processMode=1
    wlClipboard=true

    [security]
    certificate=${homeDirectory}/.config/Deskflow/tls/deskflow.pem
    checkPeerFingerprints=true
    keySize=2048
    tlsEnabled=true

    [server]
    externalConfig=true
    externalConfigFile=${deskflowServerConfig}
  '';
in {
  imports =
    (with self.nixosModules; [
      system
      shell
      desktop
      pipewire
      recomp
      shairport
      stylix
      fonts
      git-server
      emacs
      glance
      monitoring
      nfs
      ios
      local-models
    ])
    ++ [./backups.nix];

  environment = {
    systemPackages = with pkgs; [
      lm_sensors
      nvme-cli
      smartmontools
      # AMD GPU tooling
      radeontop
      vulkan-tools
      mesa-demos
      deskflow
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
          "192.168.1.52"
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

    gamescope.args = lib.mkAfter [
      # Stable PCI ID for Leo's RX 7800 XT; avoids selecting the Intel iGPU.
      "--prefer-vk-device"
      "1002:747e"
    ];

    steam.gamescopeSession.args = [
      "--adaptive-sync"
      "--hdr-enabled"
      "-W"
      "5120"
      "-H"
      "1440"
      "-r"
      "120"
    ];
  };

  networking = {
    hostName = "leo";
    domain = "home.arpa";
    # A WAN/DNS outage must not leave interactive recovery commands waiting on
    # glibc's default multi-second resolver retries. Keep the router as the
    # DNS authority for home.arpa, but fail unavailable lookups promptly.
    resolvconf.extraOptions = [
      "timeout:1"
      "attempts:1"
    ];
    firewall.interfaces.enp7s0.allowedTCPPorts = [
      config.modules.ports.alloy
      config.modules.ports.exporters.node
    ];
    hosts."192.168.1.99" = [
      "zues"
      "zues.home.arpa"
    ];
  };
  home-manager.sharedModules = homeProfiles.desktop;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = ["pcie_aspm=off"];
    #binfmt.emulatedSystems = ["aarch64-linux"];
  };

  services.lact.enable = true;

  # Keep the headless server layout declarative; the GUI cannot safely manage
  # settings while this service owns the core process.
  systemd.user.services.deskflow-server = {
    description = "Share Leo keyboard and mouse with Mac via Deskflow";
    wantedBy = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    after = ["graphical-session.target"];
    unitConfig.ConditionUser = username;
    serviceConfig = {
      ExecStart = "${pkgs.deskflow}/bin/deskflow-core server --settings ${deskflowSettings}";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  modules = {
    profile = {
      flakePath = "/mnt/smol/nixos-config";
      hashedPasswordFile = config.age.secrets.juicy-password.path;
    };
    system = {
      keyboard.zsa = true;
      highMemory.enable = true;
    };
    shell = {
      admin.enable = true;
      dev.enable = true;
    };
    desktop = {
      enable = true;
      applications.enable = true;
      gaming.enable = true;
      gaming.gamescope.session.enable = true;
      media.jellyfinMpvShim.enable = true;
      streaming.enable = true;
    };
    emacs.enable = true;
    gitServer.enable = true;
    recomp.enable = true;
    glance.enable = true;
    monitoring = {
      host.enable = true;
      diagnostics = {
        enable = true;
        smtpEmail = "maxwellb9879@gmail.com";
      };
      writablePaths = ["/mnt/chonk/backups"];
    };
    ios.enable = true;
    localModels = {
      enable = true;
      endpoint = "http://192.168.1.52:11434";
      defaultModel = "qwen3.5:9b";
    };
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
    nfs = {
      exportPath = "/srv/smol";
      firewallInterfaces = [
        "enp7s0"
      ];
    };
  };
  services = {
    syncthing = {
      enable = true;
      user = username;
      dataDir = homeDirectory;
      guiAddress = "127.0.0.1:${toString config.modules.ports.syncthing}";
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
      capSysAdmin = true;
      openFirewall = true;
      settings = {
        capture = "wlr";
        encoder = "vaapi";
        stream_audio = "disabled";
        fec_percentage = 0;
        hevc_mode = 1;
        av1_mode = 1;
        max_bitrate = 35000;
        output_name = "virtual-screen";
        port = config.modules.ports.sunshine.http;
      };
      applications.apps = let
        sunshineHyprlandStream = pkgs.writeShellScriptBin "sunshine-hyprland-stream" ''
          set -eu

          action="''${1:-}"
          remote="''${2:-false}"
          hyprctl_cmd="${pkgs.hyprland}/bin/hyprctl"
          uwsm_cmd="${lib.getExe pkgs.uwsm}"
          stream_output="virtual-screen"

          output_present() {
            expected_width="''${1:-}"
            expected_height="''${2:-}"
            if ! monitors="$("$uwsm_cmd" app -- "$hyprctl_cmd" monitors -j 2>/dev/null)"; then
              return 2
            fi
            ${lib.getExe pkgs.jq} -e \
              --arg output "$stream_output" \
              --arg width "$expected_width" \
              --arg height "$expected_height" \
              'any(.[];
                .name == $output
                and ($width == "" or .width == ($width | tonumber))
                and ($height == "" or .height == ($height | tonumber))
              )' <<<"$monitors" >/dev/null
          }

          wait_for_output() {
            expected="$1"
            expected_width="''${2:-}"
            expected_height="''${3:-}"
            attempts=0
            while [ "$attempts" -lt 50 ]; do
              if output_present "$expected_width" "$expected_height"; then
                [ "$expected" = present ] && return 0
              else
                result=$?
                [ "$result" -eq 1 ] && [ "$expected" = absent ] && return 0
              fi
              attempts=$((attempts + 1))
              ${pkgs.coreutils}/bin/sleep 0.1
            done
            echo "sunshine-hyprland-stream: timed out waiting for $stream_output to become $expected" >&2
            return 1
          }

          case "$remote" in
            true|false) ;;
            *)
              echo "usage: sunshine-hyprland-stream start true|false" >&2
              exit 2
              ;;
          esac

          case "$action" in
            start)
              width="''${SUNSHINE_CLIENT_WIDTH:-2560}"
              height="''${SUNSHINE_CLIENT_HEIGHT:-1440}"
              fps="''${SUNSHINE_CLIENT_FPS:-120}"

              "$uwsm_cmd" app -- "$hyprctl_cmd" eval "Juicy.sunshine.setStreaming(true, $remote, $width, $height, $fps)"
              wait_for_output present "$width" "$height"
              ;;
            stop)
              "$uwsm_cmd" app -- "$hyprctl_cmd" eval "Juicy.sunshine.setStreaming(false, false)"
              wait_for_output absent
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

  security.wrappers.sunshine.capabilities = lib.mkForce "cap_sys_admin,cap_sys_nice+ep";

  networking.firewall.allowedTCPPorts = [
    inputLeapPort
  ];

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
    steam-hardware.enable = true;
    openrazer = {
      enable = true;
      users = [username];
      devicesOffOnScreensaver = true;
    };
  };

  system.stateVersion = "25.11";
}
