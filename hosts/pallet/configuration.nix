{
  homeProfiles,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/system.nix
    ../../modules/common/shell.nix
    ../../modules/nixos/desktop
    ../../modules/nixos/shairport.nix
    ../../modules/common/stylix.nix
    ../../modules/nixos/fonts.nix
    ../../modules/nixos/monitoring
    ../../modules/nixos/nfs.nix
    ../../modules/common/local-models.nix
    ../../modules/nixos/nymvpn.nix
    ../../modules/nixos/tether.nix
  ];

  environment = {
    systemPackages = with pkgs; [
      lm_sensors
      nvme-cli
      smartmontools

      ifuse
      wl-clipboard
    ];
  };
  hardware = {
    enableRedistributableFirmware = true;

    nvidia = {
      # RTX 2070 (Turing): retain the NVIDIA GPU only for explicit offload jobs.
      open = true;
      modesetting.enable = true;
      powerManagement = {
        enable = true;
        finegrained = true;
      };

      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };

        # Confirm with `lspci -D -d ::03xx` if the hardware layout changes.
        intelBusId = "PCI:0@0:2:0";
        nvidiaBusId = "PCI:1@0:0:0";
      };
    };
  };

  programs = {
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
    };
  };

  networking = {
    hostName = "pallet";
    # Keep the current DHCP identity across reconnects; the factory MAC has
    # an existing reservation for another installation of this laptop.
    networkmanager.settings."connection-pallet-wifi" = {
      match-device = "interface-name:wlp0s20f3";
      "wifi.cloned-mac-address" = "56:33:6F:22:1E:49";
    };
    domain = "home.arpa";
  };

  home-manager.sharedModules = homeProfiles.desktop;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  modules = {
    system.media.enable = true;
    profile = {
      flakePath = "/mnt/smol/nixos-config";
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
      streaming.enable = true;
      terminalFileChooser.enable = true;
    };
  };

  services = {
    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "client";
      # Persist client preferences without requiring an unattended auth key.
      # Initial enrollment: sudo tailscale up
      extraSetFlags = [
        "--accept-dns=false"
        "--accept-routes"
        "--operator=juicy"
      ];
    };
    thermald.enable = true;
    xserver.videoDrivers = ["nvidia"];

    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = ["/"];
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

  fileSystems = {
    "/mnt/smol" = {
      device = "192.168.1.54:/srv/smol/";
      fsType = "nfs";
      options = [
        "nfsvers=4"
        "_netdev"
        "noatime"
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=15s"
      ];
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
  system.stateVersion = "25.11";
}
