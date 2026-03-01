{
  nix-config,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) attrValues;

  domain = "nixlab.au";
  turnHost = "turn.nixlab.au";
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
    ports
  ];
  home-manager.sharedModules = attrValues nix-config.homeModules;
  environment.systemPackages = lib.optionals (nix-config ? packages) (
    attrValues nix-config.packages.${pkgs.stdenv.hostPlatform.system}
  );
  environment.sessionVariables.FLAKE = "/home/juicy/nixos-config";

  age.secrets = {
    juicy-password.file = ../../secrets/juicy-password.age;
    coturn-key = {
      file = ../../secrets/coturn-key.age;
      owner = "turnserver";
      group = "turnserver";
      mode = "0400";
    };
  };

  # Custom modules
  modules = {
    system = {
      username = "juicy";
      hostName = "fallarbor";
      hashedPasswordFile = config.age.secrets.juicy-password.path;
    };
  };
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  services.journald.extraConfig = ''
    SystemMaxUse=100M
    RuntimeMaxUse=50M
    MaxFileSec=1day
  '';
  nix.settings = {
    max-jobs = 1;
    build-cores = 1;
  };

  services.fail2ban.enable = true;

  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ 3478 ];
    allowedTCPPorts = [ 3478 ];
    allowedUDPPortRanges = [
      {
        from = 49152;
        to = 49999;
      }
    ];
  };

  # Coturn reads the auth secret from an age-managed file.
  services.coturn = {
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

  # Secret provisioning via systemd credentials + runtime conf merge
  # We create /run/coturn/turn-extra.conf at start, injecting the secret safely.
  systemd.tmpfiles.rules = [
    "d /run/coturn 0750 turnserver turnserver -"
  ];

  # Optional host entry
  networking.hosts."${turnHost}" = [
    "127.0.0.1"
    "::1"
  ];
}
