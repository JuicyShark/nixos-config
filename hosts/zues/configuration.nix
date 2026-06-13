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
    unbound
    nfs
    acme
  ];

  networking.hostName = "zues";
  environment.variables.FLAKE = "/mnt/chonk/self";
  programs.nh.flake = "/mnt/chonk/self";
  home-manager.sharedModules = homeProfiles.cli;

  system.autoUpgrade = {
    enable = true;
    flake = "/mnt/chonk/self";
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
    profile.hashedPasswordFile = config.age.secrets.juicy-password.path;
    homelab = {
      smtpEmail = "maxwellb9879@gmail.com";
      deluge.enable = true;
      filebrowser.enable = true;
      headscale.enable = true;
      jellyfin.enable = true;
      media.enable = true;
      syncthing.enable = false;
      gatus.enable = true;
      vaultwarden.enable = true;
    };
    monitoring = {
      enable = true;
      host.enable = true;
      nas.enable = true;
    };
    nfs = {
      exportPath = "/srv/chonk";
      # Restrict to known clients only; all clients are squashed to media.
      allowedHosts = [
        "192.168.1.54"
        "192.168.1.52"
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

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "both";
    extraUpFlags = [
      "--login-server=https://ts.nixlab.au"
      "--accept-dns=false"
      "--accept-routes"
      "--advertise-routes=192.168.1.0/24"
    ];
  };
}
