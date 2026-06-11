{
  self,
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
  imports = with self.nixosModules; [
    system
    shell
    monitoring
  ];
  environment.systemPackages = with pkgs; [
    tcpdump
    iperf3
  ];

  environment.variables.FLAKE = "/home/juicy/nixos-config";
  programs.nh.flake = "/home/juicy/nixos-config";
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
    profile.hashedPasswordFile = config.age.secrets.juicy-password.path;
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
      trusted = true;
      keys = [leoBuilderKey];
    };
  };

  boot.kernel.sysctl."vm.swappiness" = 10;

  networking = {
    hostName = "fallarbor";

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
      interfaces.tailscale0.allowedTCPPorts = [config.modules.ports.exporters.node];
    };

    # Optional host entry
    hosts."${turnHost}" = [
      "127.0.0.1"
      "::1"
    ];
  };

  services = {
    journald.extraConfig = ''
      SystemMaxUse=100M
      RuntimeMaxUse=50M
      MaxFileSec=1day
      RateLimitInterval=30s
      RateLimitBurst=1000
    '';

    fail2ban.enable = true;

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

  # Secret provisioning via systemd credentials + runtime conf merge
  # We create /run/coturn/turn-extra.conf at start, injecting the secret safely.
  systemd.tmpfiles.rules = [
    "d /run/coturn 0750 turnserver turnserver -"
  ];
}
