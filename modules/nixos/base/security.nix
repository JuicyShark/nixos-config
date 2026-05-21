# Security Configuration
#
# Manages SSH, sudo, PAM, and security-related settings.
{
  config,
  lib,
  ...
}: let
  cfg = config.modules.system;
in {
  config = {
    services.openssh = {
      enable = true;
      openFirewall = false;
      settings = {
        PubkeyAuthentication = true;
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
        UseDns = false;
      };
    };

    # Allow SSH only from LAN and Tailscale CGNAT range; block WAN scanners
    networking.firewall.extraInputRules = ''
      ip saddr ${config.modules.network.subnets.lan} tcp dport 22 accept
      ip saddr ${config.modules.network.subnets.tailscale} tcp dport 22 accept
    '';

    programs = {
      command-not-found.enable = true;
      ssh.startAgent = false;
    };

    security.sudo.extraConfig = ''
      Defaults env_keep += "EDITOR VISUAL"
    '';

    security.pam.sshAgentAuth = {
      enable = true;
      authorizedKeysFiles = ["/etc/ssh/authorized_keys.d/%u"];
    };

    services.fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
    };

    hardware.keyboard.zsa.enable = lib.mkIf cfg.keyboard.zsa true;
  };
}
