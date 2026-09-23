# Security Configuration
#
# Manages SSH, sudo, PAM, and security-related settings.
{
  config,
  inputs,
  pkgs,
  ...
}: let
  isDesktop = config.modules.desktop.enable or false;
in {
  config = {
    services.openssh = {
      enable = true;
      openFirewall = false;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        UseDns = false;
      };
    };

    # Allow SSH only from LAN and Tailscale CGNAT range; block WAN scanners
    networking.firewall.extraInputRules = ''
      ip saddr 192.168.1.0/24 tcp dport 22 accept
      ip saddr 100.64.0.0/10 tcp dport 22 accept
    '';

    programs = {
      command-not-found.enable = false;
      nix-index = {
        enable = true;
        package = inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.nix-index-with-small-db;
      };
      nix-index-database.comma.enable = true;
      gnupg.agent = {
        enable = true;
        pinentryPackage =
          if isDesktop
          then pkgs.pinentry-qt
          else pkgs.pinentry-curses;
        settings = {
          default-cache-ttl = 3600;
          max-cache-ttl = 14400;
        };
      };
    };

    security.sudo.extraConfig = ''
      Defaults env_keep += "EDITOR VISUAL"
    '';

    security.pam.sshAgentAuth = {
      enable = true;
      authorizedKeysFiles = ["/etc/ssh/authorized_keys.d/%u"];
    };
  };
}
