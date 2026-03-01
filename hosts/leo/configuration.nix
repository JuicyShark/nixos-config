{
  nix-config,
  config,
  pkgs,
  ...
}:
let
  inherit (builtins) attrValues;
in
{
  imports = with nix-config.nixosModules; [
    system
    shell
    desktop
    stylix
    fonts
    emacs
    sunshine
    glance
    monitoring
    network
    ports
    nfs
  ];

  home-manager.sharedModules = attrValues nix-config.homeModules;
  environment.sessionVariables.FLAKE = "/mnt/smol/nixos-config";

  networking.firewall = {
    allowedUDPPorts = [
      47998 # Sunshine
      48000 # Sunshine
    ];
  };

  age.secrets = {
    prowlarr-api = {
      file = ../../secrets/prowlarr-api.age;
    };
    radarr-api = {
      file = ../../secrets/radarr-api.age;
    };
    sonarr-api = {
      file = ../../secrets/sonarr-api.age;
    };
    lidarr-api = {
      file = ../../secrets/lidarr-api.age;
    };

    bazarr-api = {
      file = ../../secrets/bazarr-api.age;
    };

    jellyfin-api = {
      file = ../../secrets/jellyfin-api.age;
      owner = config.modules.system.username;
      group = "users";
      mode = "0400";
    };
  };

  modules = {
    system = {
      roles = [
        "desktop"
        "desktop-bloat"
        "desktop-gaming"
        "desktop-gui-fallback"
        "desktop-streaming"
        "desktop-sunshine"
        "desktop-emacs"
        "homelab-glance"
        "keyboard-zsa"
        "peon-ping"
        "ram-high"
      ];
      username = "juicy";
      hostName = "leo";
      hashedPasswordFile = config.age.secrets.juicy-password.path;
    };
    desktop = {
      primaryMonitorName = "DP-2";
    };
    nfs = {
      exportPath = "/srv/smol";
    };
  };
  services = {
    hardware.openrgb = {
      enable = true;
      motherboard = "intel";
      package = pkgs.openrgb-with-all-plugins;
    };

    journald.extraConfig = ''
      SystemMaxUse=512M
      RuntimeMaxUse=256M
      MaxFileSec=7day
    '';
    fstrim.enable = true;
    irqbalance.enable = true;
  };
  fileSystems."/mnt/games" = {
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
  fileSystems."/mnt/games/SteamLibrary/steamapps/compatdata" = {
    device = "/home/juicy/.steam/steamcompat";
    fsType = "none";
    options = [ "bind" ];
  };
  fileSystems."/mnt/games/SteamLibrary/steamapps/shadercache" = {
    device = "/home/juicy/.steam/shadercache";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/srv/smol" = {
    device = "/dev/disk/by-uuid/85a1714c-447f-4324-99af-dc0bf3b16b3d";
    fsType = "btrfs";
    options = [
      "noatime"
      "nofail"
      "x-systemd.automount"
      "x-systemd.device-timeout=15s"
    ];
  };

  fileSystems."/mnt/torrents" = {
    device = "/dev/disk/by-uuid/b296f7f1-ac9e-411c-98ac-4d6b6b13a6b5";
    fsType = "btrfs";
    options = [
      "noatime"
      "nofail"
      "x-systemd.automount"
      "x-systemd.device-timeout=15s"
    ];
  };

  fileSystems."/mnt/chonk" = {
    device = "192.168.1.99:/srv/chonk";
    fsType = "nfs";
    options = [
      "nfsvers=4"
      "x-systemd.automount"
      "nofail"
    ];
  };

  fileSystems."/mnt/smol" = {
    device = "/srv/smol";
    fsType = "none";
    options = [ "bind" ];
  };

  hardware.openrazer.enable = true;
}
