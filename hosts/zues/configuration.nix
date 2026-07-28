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
    monitoring
    stylix
    unbound
    nfs
    acme
  ];

  networking = {
    hostName = "zues";
    domain = "home.arpa";
  };
  environment.variables.FLAKE = "/mnt/smol/nixos-config";
  programs.nh.flake = "/mnt/smol/nixos-config";
  home-manager.sharedModules = homeProfiles.cli;

  # Keep the shared palette and console target without enabling desktop theme
  # integrations or their packages on the headless router/NAS.
  stylix.autoEnable = lib.mkForce false;

  # The shared flake is a mutable working tree. Upgrades remain an intentional
  # remote deployment from Leo instead of a router-side unattended switch.
  system.autoUpgrade.enable = false;

  modules = {
    profile.hashedPasswordFile = config.age.secrets.juicy-password.path;
    homelab = {
      smtpEmail = "maxwellb9879@gmail.com";
      filebrowser.enable = true;
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
    system.media.enable = true;
    shell.admin.enable = true;
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
    pv
    restic
    smartmontools
    nvme-cli
  ];

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--accept-dns=false"
      "--advertise-routes=192.168.1.0/24"
    ];
  };

  nix.sshServe = {
    enable = true;
    protocol = "ssh-ng";
    write = true;
    trusted = true;
    keys = [leoBuilderKey];
  };

  system.stateVersion = "25.11";
}
