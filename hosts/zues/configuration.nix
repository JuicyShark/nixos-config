{
  self,
  homeProfiles,
  config,
  pkgs,
  lib,
  ...
}: let
  leoBuilderKey = lib.removeSuffix "\n" (builtins.readFile ../leo/id_ed25519.pub);
in {
  imports = with self.nixosModules; [
    system
    shell
    homelab
    filebrowser
    monitoring
    stylix
    tailscale
    unbound
    nfs
    acme
  ];

  system.autoUpgrade = {
    enable = true;
    flake = config.modules.system.flakePath;
    dates = "Sun 04:00";
    randomizedDelaySec = "45min";
    persistent = true;
    operation = "switch";
    allowReboot = true;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L"
    ];
  };

  modules = {
    system = {
      flakePath = "/mnt/chonk/self";
      hostName = "zues";
      hashedPasswordFile = config.age.secrets.juicy-password.path;
      homeModules = homeProfiles.cli;
    };
    homelab = {
      smtpEmail = "maxwellb9879@gmail.com";
      deluge.enable = true;
      headscale.enable = true;
      immich.enable = false;
      jellyfin.enable = true;
      media.enable = true;
      miniflux.enable = false;
      paperless.enable = false;
      syncthing.enable = false;
      gatus.enable = true;
      vaultwarden.enable = true;
    };
    monitoring = {
      enable = true;
      host.enable = true;
      nas.enable = true;
    };
    filebrowser = {
      enable = true;
    };
    tailscale = {
      enable = true;
      routingMode = "both";
      advertiseRoutes = [config.modules.network.subnets.lan];
    };
    nfs = {
      exportPath = "/srv/chonk";
      # Restrict to known clients only; all clients are squashed to media.
      allowedHosts = with config.modules.network.hosts; [
        leo
        imac-machop
      ];
      anonUid = 2000;
      anonGid = 2000;
    };
  };

  environment.systemPackages = with pkgs; [
    # Router / homelab diagnostics
    iperf3
    ethtool
    tcpdump
    conntrack-tools
    nethogs
    iftop
    pv
    restic
    smartmontools
    nvme-cli
    lsof
  ];

  nix.sshServe = {
    enable = true;
    protocol = "ssh-ng";
    write = true;
    trusted = true;
    keys = [leoBuilderKey];
  };
}
