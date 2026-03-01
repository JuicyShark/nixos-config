# Security Configuration
#
# Manages SSH, sudo, PAM, and security-related settings.
# Extracted from system.nix for better modularity.

{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.system;
  hasRole = role: builtins.elem role cfg.roles;
in
{
  config = {
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PubkeyAuthentication = true;
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
        UseDns = false;
      };
    };

    programs = {
      command-not-found.enable = true;
      ssh.startAgent = false;
    };

    security.sudo.extraConfig = ''
      Defaults env_keep += "EDITOR VISUAL"
    '';

    security.pam.sshAgentAuth = {
      enable = true;
      authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
    };

    # Hardware-specific security
    hardware.keyboard.zsa.enable = mkIf (hasRole "keyboard-zsa") true;
  };
}
