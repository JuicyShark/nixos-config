{
  ports,
  homeProfiles,
  config,
  pkgs,
  lib,
  ...
}: let
  domain = "nixlab.au";
  turnHost = "turn.nixlab.au";
  leoBuilderKey = lib.removeSuffix "\n" (builtins.readFile ../leo/id_ed25519.pub);
in {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/system.nix
    ../../modules/common/shell.nix
    ../../modules/nixos/monitoring
  ];
  environment.systemPackages = with pkgs; [
    tcpdump
    iperf3
  ];

  home-manager.sharedModules = homeProfiles.cli;

  age.secrets = {
    coturn-key = {
      file = ../../secrets/coturn-key.age;
      owner = "turnserver";
      group = "turnserver";
      mode = "0400";
    };
  };

  modules = {
    profile = {
      flakePath = "/home/${config.modules.profile.username}/nixos-config";
    };
    monitoring.host.enable = true; # ship logs to zues Loki + expose node metrics
  };
  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };

    settings = {
      max-jobs = 1;
      build-cores = 1;
    };

    sshServe = {
      enable = true;
      protocol = "ssh-ng";
      write = true;
      # Permit store uploads without granting trusted-client privileges.
      trusted = false;
      keys = [leoBuilderKey];
    };
  };

  boot.kernel.sysctl."vm.swappiness" = 10;

  networking = {
    hostName = "fallarbor";
    inherit domain;

    firewall = {
      enable = true;
      allowedUDPPorts = [3478];
      allowedTCPPorts = [3478];
      allowedUDPPortRanges = [
        {
          from = 49152;
          to = 49999;
        }
      ];
      # Open node_exporter for Tailscale scraping from zues
      interfaces.tailscale0.allowedTCPPorts = [ports.exporters.node];
    };

    # Optional host entry
    hosts."${turnHost}" = [
      "127.0.0.1"
      "::1"
    ];
  };

  services = {
    journald.settings.Journal = {
      SystemMaxUse = "100M";
      RuntimeMaxUse = "50M";
      MaxFileSec = "1day";
      RateLimitIntervalSec = "30s";
      RateLimitBurst = 1000;
    };

    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "client";
      extraUpFlags = [
        "--accept-dns=false"
        "--accept-routes"
      ];
    };

    # Coturn reads the auth secret from an age-managed file.
    coturn = {
      enable = true;
      use-auth-secret = true;
      static-auth-secret-file = config.age.secrets.coturn-key.path;
      realm = domain;
      no-tls = true;
      no-tcp-relay = true;
      listening-port = 3478;
      min-port = 49152;
      max-port = 49999;
      extraConfig = ''
        fingerprint
        stale-nonce=600
        no-cli
        no-loopback-peers
        no-multicast-peers
      '';
    };
  };

  system.stateVersion = "25.11";
}
