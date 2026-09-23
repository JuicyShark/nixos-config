{
  inputs,
  homeProfiles,
  homelabFeatures,
  pkgs,
  lib,
  ...
}: let
  smtpEmail = "maxwellb9879@gmail.com";
  leoBuilderKey = lib.removeSuffix "\n" (builtins.readFile ../leo/id_ed25519.pub);
in {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/system.nix
    ../../modules/common/shell.nix
    ../../modules/nixos/homelab
    ../../modules/nixos/monitoring
    ../../modules/common/stylix.nix
    ../../modules/nixos/nfs.nix
    ./networking.nix
    ./services.nix
    ./gatus.nix
    inputs.nixflix.nixosModules.default
    ../../modules/nixos/homelab/nixflix-prowlarr-indexers.nix
  ];

  disabledModules = ["${inputs.nixflix}/modules/prowlarr/indexers.nix"];

  networking = {
    hostName = "zues";
    domain = "home.arpa";
  };
  home-manager.sharedModules = homeProfiles.cli;

  stylix.autoEnable = lib.mkForce false;

  system.autoUpgrade.enable = false;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  boot.loader.systemd-boot.configurationLimit = lib.mkForce 2;

  modules = {
    profile = {
      flakePath = "/mnt/smol/nixos-config";
    };
    homelab = {
      jellyfin.enable = homelabFeatures.jellyfin;
      jellystat.enable = homelabFeatures.jellystat;
      media.enable = homelabFeatures.media;
      swiparr.enable = homelabFeatures.swiparr;
      tidarr.enable = homelabFeatures.tidarr;
    };
    monitoring = {
      enable = homelabFeatures.monitoring;
      alertEmail = smtpEmail;
      host.enable = true;
      nas.enable = true;
      vpnGuard = {
        service = "qbittorrent.service";
        namespace = "wg";
      };
    };
    system.media.enable = true;
    shell = {
      dev.enable = lib.mkForce false;
      admin.enable = true;
      atuin.syncUrl = "http://atuin.home.arpa";
    };
    nfs = {
      exportPath = "/srv/chonk";
      # Restrict to known clients only; all clients are squashed to media.
      allowedHosts = [
        "192.168.1.14"
        "192.168.1.54"
        "192.168.1.47"
        "192.168.1.52"
      ];
      anonUid = 1000;
      anonGid = 2000;
    };
  };

  environment.systemPackages = with pkgs; [
    # Router / homelab diagnostics
    iperf3
    ethtool
    tcpdump
    conntrack-tools
    pv
    smartmontools
    nvme-cli
  ];

  services = {
    atuin.enable = homelabFeatures.atuin;
    filebrowser.enable = homelabFeatures.filebrowser;
    gatus.enable = homelabFeatures.gatus;
    syncthing.enable = homelabFeatures.syncthing;
    vaultwarden = {
      enable = homelabFeatures.vaultwarden;
      config = {
        SMTP_FROM = smtpEmail;
        SMTP_USERNAME = smtpEmail;
      };
    };

    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "server";
      extraUpFlags = [
        "--accept-dns=false"
        "--advertise-routes=192.168.1.0/24"
        "--operator=juicy"
      ];
    };
  };

  systemd.services.tailscale-udp-gro-forwarding = {
    description = "Optimize UDP forwarding for Tailscale";
    wantedBy = ["multi-user.target"];
    before = ["tailscaled.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ethtool}/bin/ethtool -K enp1s0 rx-udp-gro-forwarding on rx-gro-list off";
      RemainAfterExit = true;
    };
  };

  nix.sshServe = {
    enable = true;
    protocol = "ssh-ng";
    write = true;
    # Permit store uploads without granting trusted-client privileges.
    trusted = false;
    keys = [leoBuilderKey];
  };

  system.stateVersion = "25.11";
}
