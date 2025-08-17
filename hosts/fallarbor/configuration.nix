{
  inputs,
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

  # Path to your age/agenix or sops-nix decrypted secret on disk at runtime.
  # Example with agenix:
  #   age.secrets.coturn-secret.file = ./secrets/coturn-secret.age;
  #   -> then the decrypted file is at config.age.secrets.coturn-secret.path
  # secretPath = config.age.secrets.coturn-secret.path or "/run/keys/coturn-secret"; # replace if not using agenix
in

{
  imports = attrValues nix-config.nixosModules;
  home-manager.sharedModules = attrValues nix-config.homeModules;
  environment.systemPackages = attrValues nix-config.packages.${pkgs.system};
  environment.sessionVariables.FLAKE = "/mnt/chonk/nix-config";

  # Custom modules
  modules = {
    desktop.enable = false;
    system = {
      mullvad = false;
      username = "juicy";
      hostName = "fallarbor";
      hashedPassword = "$y$j9T$j5oMkFeAEFqm.TmI9Yql/0$nMZGLBa0Y5E2ORwPbIr1oHVUS2jZJUjFjPPWP.SAmR8";
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
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
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

  # Coturn base config WITHOUT the static-auth-secret
  services.coturn = {
    enable = true;
    use-auth-secret = true;
    static-auth-secret = "ZW1lcmFsZFR1cm5TZWNyZXQ=";
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

  # If you use agenix:
  #age.secrets.coturn-secret.file = ./secrets/coturn-secret.age;
  # Make sure its contents is the *raw secret string* that Synapse also uses.

  /*
    systemd.services.coturn = {
      # Pass the secret to the unit as a credential file
      serviceConfig.LoadCredential = [ "TURN_SECRET:${secretPath}" ];
      # Create a small extra conf at runtime that contains the secret
      preStart = ''
        set -eu
        cred="/run/credentials/coturn.service/TURN_SECRET"
        if [ ! -s "$cred" ]; then
          echo "TURN secret credential missing" >&2
          exit 1
        fi
        install -m 0640 -o turnserver -g turnserver /dev/null /run/coturn/turn-extra.conf
        printf "static-auth-secret=%s\n" "$(tr -d '\n' < "$cred")" > /run/coturn/turn-extra.conf
      '';
      # Make coturn also read our runtime file
      serviceConfig.ExecStart = lib.mkForce ''
        ${pkgs.coturn}/bin/turnserver -c /etc/turnserver.conf -c /run/coturn/turn-extra.conf
      '';
    };
  */

  # Optional host entry
  networking.hosts."${turnHost}" = [
    "127.0.0.1"
    "::1"
  ];

}
